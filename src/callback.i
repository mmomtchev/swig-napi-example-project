// This enables the special std::string conversion maps
// Without it, SWIG will wrap the C++ std::string as any other type
%include <std_string.i>

%include <std_map.i>

%{
// This goes into the wrapper code
#include "callback.h"
#include <vector>
%}

// ==========================================================
// This typemap converts a JS callback to a C++ std::function
// ==========================================================

#ifdef NO_ASYNC
// This is the synchronous version, it creates a Local function reference (js_callback)
// that exists for the duration of the call
%typemap(in) std::function<std::string(int, const std::string &)> giver (Napi::Function js_callback) {
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  js_callback = $input.As<Napi::Function>();

  // $1 is what we pass to the C++ function -> it is a C++ wrapper
  // around the JS callback
  $1 = [&js_callback, &env](int passcode, const std::string &name) -> std::string {
    // Convert the C++ arguments to JS
    // ($typemap with arguments is currently an undocumented
    // but very useful SWIG feature that is not specific to SWIG JSE)
    std::vector<napi_value> js_args = {napi_value{}, napi_value{}};
    $typemap(out, int, 1=passcode, result=js_args.at(0), argnum=callback argument 1);
    $typemap(out, std::string, 1=name, result=js_args.at(1), argnum=callback argument 2);

    // Call the JS callback
    Napi::Value js_ret = js_callback.Call(env.Undefined(), js_args);

    // Handle the JS return value
    std::string c_ret;
    $typemap(in, std::string, input=js_ret, 1=c_ret, argnum=JavaScript callback return value)
    return c_ret;
  };
}

#else

// This is how you make a macro valid for both SWIG and the compiler
#define ASYNC_CALLBACK_SUPPORT
%{
#define ASYNC_CALLBACK_SUPPORT
%}

// Create async versions of GiveMeFive
%feature("async", "Async") GiveMeFive;
%feature("async", "_Async") GiveMeFive_C_wrapper;

// This is the version that supports both synchronous and asynchronous calling
// and can resolve automatically Promises returned from JS (ie it supports JS async callbacks)
// It uses the rather complex SWIG_NAPI_Callback code fragment that is candidate for inclusion
// in the SWIG JSE standard library
%include <swig_napi_callback.i>
%typemap(in, fragment="SWIG_NAPI_Callback") std::function<std::string(int, const std::string &)> giver {
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  
  $1 = SWIG_NAPI_Callback<std::string, int, const std::string &>(
    $input,
    // For some unknown (to me) reason implicit std::function construction from a lambda does not
    // work for an std:function using variadic arguments on all C++ compilers
    // Given that my StackOverflow C++ questions always end up as violent pissing contests
    // I prefer to avoid starting a new one, but this discussion confirms the issue:
    // https://stackoverflow.com/questions/9242234/c11-variadic-stdfunction-parameter
    std::function<void(Napi::Env, std::vector<napi_value> &, int, const std::string &)>(
        [](Napi::Env env, std::vector<napi_value> &js_args, int passcode, const std::string &name) -> void {
        $typemap(out, int, 1=passcode, result=js_args.at(0), argnum=callback argument 1);
        $typemap(out, std::string, 1=name, result=js_args.at(1), argnum=callback argument 2);
      }
    ),
    [](Napi::Env env, Napi::Value js_ret) -> std::string {
      std::string c_ret;
      $typemap(in, std::string, input=js_ret, 1=c_ret, argnum=JavaScript callback return value)
      return c_ret;
    },
    [](Napi::Env env, Napi::Function js_callback, const std::vector<napi_value> &js_args) -> Napi::Value {
      return js_callback.Call(env.Undefined(), js_args);
    }
  );
}
#endif

// This is the TypeScript type associated
#ifdef ASYNC_CALLBACK_SUPPORT
%typemap(ts) std::function<std::string(int, const std::string &)> giver "(pass: number, name: string) => Promise<string> | string";
#else
%typemap(ts) std::function<std::string(int, const std::string &)> giver "(pass: number, name: string) => string";
#endif

// Example for wrapping a function that expects a C-style function pointer
// It must support passing a context pointer and it will be replaced by the wrapper
%ignore GiveMeFive_C;
%rename(GiveMeFive_C) GiveMeFive_C_wrapper;
// Declare the function for SWIG
%inline {
std::string GiveMeFive_C_wrapper(std::function<std::string(int, const std::string &)> giver);
}

// Embed its implementation in the generated code
%wrapper %{
std::string GiveMeFive_C_wrapper(std::function<std::string(int, const std::string &)> giver) {
  // In this particular example giver should be valid in the lambda
  // But in order to support functions that keep the callback and call it
  // later, we choose to make a copy.
  // This also protects from unexpected return value optimizations by the
  // compiler.
  using cb_t = decltype(giver);
  auto *cb = new cb_t{giver};
  return GiveMeFive_C(
      [](void *data, int arg1, const std::string &arg2) -> std::string {
        auto giver_ = reinterpret_cast<cb_t*>(data);
        auto result = (*giver_)(arg1, arg2);
        // If the underlying code will continue calling this function
        // it should not be deleted, in this case example it is used
        // for a single call
        delete giver_;
        return result;
      },
      cb);
}
%}

// Bring in all the function definitions
%include <callback.h>
