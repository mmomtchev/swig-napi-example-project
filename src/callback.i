// This enables the special std::string conversion maps
// Without it, SWIG will wrap the C++ std::string as a special type
%include <std_string.i>

%include <std_map.i>

%{
// This goes into the wrapper code
#include "callback.h"
%}

// This typemap converts a JS callback to a C++ std::function
// This is the synchronous version, it creates a Local function reference (js_callback)
// that exists for the duraction of the call
%typemap(in) std::function<std::string(int)> giver (Napi::Function js_callback) {
  if (!$input.IsFunction()) {
    %argument_fail(SWIG_TypeError, "$type", $symname, $argnum);
  }
  js_callback = $input.As<Napi::Function>();
  // $1 is what we pass to the C++ function -> it is a C++ wrapper
  // around the JS callback
  $1 = [&js_callback, &env](int passcode) -> std::string {
    // Convert the int passcode to JS Number
    Napi::Number js_passcode = Napi::Number::New(env, passcode);
    napi_value js_arg1 = js_passcode;
    Napi::Value js_ret = js_callback.Call(env.Undefined(), {js_arg1});
    // Handle the JS return value
    if (!js_ret.IsString()) {
      throw Napi::Error::New(env, "JavaScript callback did not return a string");
    }
    return js_ret.ToString().Utf8Value();
  };
}
// This is the TypeScript type associated
%typemap(ts) std::function<std::string(int)> giver "(pass: number) => string";

// Bring in all the function definitions
%include <callback.h>
