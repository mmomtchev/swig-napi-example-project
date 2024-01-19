#ifndef SWIG_JAVASCRIPT_EVOLUTION
#error blob requires SWIG JavaScript Evolution
#endif

%{
  // This goes into the wrapper code
  #include "array.h"
%}

/**
 * Handle std::vector
 * TODO: this should probably be part of the standard SWIG Node-API library
 */

/* -------------------------- */
/* const std::vector typemaps */
/* -------------------------- */
%typemap(in)        std::vector<IntObject> const & {
  // Has JS passed an array?
  if ($input.IsArray()) {
    // Construct an std::vector out of it
    $1 = new std::vector<IntObject>;
    Napi::Array array = $input.As<Napi::Array>();
    for (size_t i = 0; i < array.Length(); i++) {
      // Do it IntObject by IntObject
      IntObject *p = nullptr;
      // $descriptor(IntObject *) is the SWIG descriptor type
      if (!SWIG_IsOK(SWIG_NAPI_ConvertPtr(array.Get(i), reinterpret_cast<void **>(&p), $descriptor(IntObject *), 0)) || p == nullptr) {
        SWIG_exception_fail(SWIG_TypeError, "in method '$symname', array element is not an IntObject");
      }
      // Emplace the newly constructed wrappers in the std::vector
      $1->emplace_back(IntObject(*p));
    }
  } else {
    SWIG_exception_fail(SWIG_TypeError, "in method '$symname', argument $argnum is not an array");
  }
}
%typemap(freearg)   std::vector<IntObject> const & {
  // Free the std::vector on leaving the wrapper
  delete $1;
}
// signal to TypeScript what to require
%typemap(ts)        std::vector<IntObject> const & "IntObject[]";




/* --------------------------- */
/* argout std::vector typemaps */
/* --------------------------- */
%typemap(out)       std::vector<IntObject> {
  // Construct a JS array out of the std::vector
  Napi::Array array = Napi::Array::New(env, $1.size());
  for (size_t i = 0; i < $1.size(); i++) {
    // We copy each IntObject and we tell JavaScript (SWIG, NAPI...) that it will own it
    IntObject *p = new IntObject($1.at(i));
    // We create JS proxies out of the C++ IntObjects
    Napi::Value val = SWIG_NAPI_NewPointerObj(env, p, $descriptor(IntObject *), SWIG_POINTER_OWN);
    // And we push them into the array
    array.Set(i, val);
  }
  // This is the returned value
  $result = array;
}
// signal to TypeScript what to expect
%typemap(ts)        std::vector<IntObject> "IntObject[]";


// Bring in all the function definitions
%include <array.h>
