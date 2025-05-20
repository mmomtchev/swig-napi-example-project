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
// using the built-in helper SWIG_NAPI_Callback
// ==========================================================

#ifndef NO_ASYNC
// Create async versions of GiveMeFive and JustCall
%feature("async", "Async") GiveMeFive;
%feature("async", "Async") JustCall;
%feature("async", "_Async") GiveMeFive_C_wrapper;
#endif

%typemap(in) std::function<std::string(int, const std::string &)> giver {
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
    env.Global()
  );
}

// Same but for void (*)()
%typemap(in) std::function<void()> cb {
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  
  $1 = SWIG_NAPI_Callback<void>(
    $input,
    // Empty input typemaps
    std::function<void(Napi::Env, std::vector<napi_value> &)>(
        [](Napi::Env env, std::vector<napi_value> &) -> void {}
    ),
    /// Empty output typemap
    [](Napi::Env env, Napi::Value) -> void {},
    env.Global()
  );
}

// This is the TypeScript type associated
#ifdef NO_ASYNC
%typemap(ts) std::function<std::string(int, const std::string &)> giver "(this: typeof globalThis, pass: number, name: string) => string";
%typemap(ts) std::function<void()> cb "(this: typeof globalThis) => void";
#else
%typemap(ts) std::function<std::string(int, const std::string &)> giver "(this: typeof globalThis, pass: number, name: string) => Promise<string> | string";
%typemap(ts) std::function<void()> cb "(this: typeof globalThis) => Promise<void> | void";
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
