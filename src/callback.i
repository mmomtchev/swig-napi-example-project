// This enables the special std::string conversion maps
// Without it, SWIG will wrap the C++ std::string as any other type
%include <std_string.i>

%include <std_map.i>

%{
// This goes into the wrapper code
#include "callback.h"
#include <vector>
%}

// This typemap converts a JS callback to a C++ std::function
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

// This is the asynchronous version, it works both in asynchronous
// and synchronous mode (but it is slightly less efficient than the fully sync one)
%fragment("threads", "wrapper") %{
  #include <thread>
  #include <condition_variable>
%}
%typemap(in, fragment="threads") std::function<std::string(int, const std::string &)> giver
  (Napi::ThreadSafeFunction *tsfn, Napi::FunctionReference *syncfn) {

  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  tsfn = new Napi::ThreadSafeFunction(Napi::ThreadSafeFunction::New(env,
    $input.As<Napi::Function>(),
    Napi::Object::New(env),
    "example_async_resource",
    0,
    1
  ));
  syncfn = new Napi::FunctionReference(Napi::Persistent($input.As<Napi::Function>()));
  // Here we are in the main V8 thread
  auto main_thread_id = std::this_thread::get_id();

  // $1 is what we pass to the C++ function -> it is a C++ wrapper
  // around the JS callback
  $1 = [tsfn, syncfn, env, main_thread_id](int passcode, const std::string &name) -> std::string {
    std::string c_ret;
    std::mutex m;
    std::condition_variable cv;
    bool ready = false;

    auto do_call = [&c_ret, &passcode, &name, &m, &cv, &ready](Napi::Env env, Napi::Function js_fn) {
      // Here we are back in the main V8 thread

      // Convert the C++ arguments to JS
      // ($typemap with arguments is currently an undocumented
      // but very useful SWIG feature that is not specific to SWIG JSE)
      std::vector<napi_value> js_args = {napi_value{}, napi_value{}};
      $typemap(out, int, 1=passcode, result=js_args.at(0), argnum=callback argument 1);
      $typemap(out, std::string, 1=name, result=js_args.at(1), argnum=callback argument 2);

      // Call the JS callback
      Napi::Value js_ret = js_fn.Call(env.Undefined(), js_args);

      // Handle the JS return value
      $typemap(in, std::string, input=js_ret, 1=c_ret, argnum=JavaScript callback return value);
      std::unique_lock lock{m};
      ready = true;
      lock.unlock();
      cv.notify_one();
    };

    // Are we in the thread pool background thread (V8 is not accessible) or not?
    if (std::this_thread::get_id() == main_thread_id) {
      do_call(env, syncfn->Value());
    } else {
      tsfn->BlockingCall();
    }
    std::unique_lock lock{m};
    cv.wait(lock, [&ready]{ return ready; });
    return c_ret;
  };
}
#endif

// This is the TypeScript type associated
%typemap(ts) std::function<std::string(int, const std::string &)> giver "(pass: number, name: string) => string";

// Bring in all the function definitions
%include <callback.h>
