%module blob

#ifndef SWIG_JAVASCRIPT_EVOLUTION
#error blob requires SWIG JavaScript Evolution
#endif

%{
  #include <blob.h>
%}

%include <arraybuffer.i>
%include <exception.i>

// Rethrow all C++ exceptions as JS exceptions
%exception {
  try {
    $action
  } catch (const std::exception &e) {
    SWIG_Raise(e.what());
    SWIG_fail;
  }
}

// Use the standard ArrayBuffer typemaps
%typemap(in)        (uint8_t *data, size_t len) = (void *arraybuffer_data, size_t arraybuffer_len);
%typemap(typecheck) (uint8_t *data, size_t len) = (void *arraybuffer_data, size_t arraybuffer_len);
%typemap(argout)    (uint8_t *data, size_t len) = (void *arraybuffer_data, size_t arraybuffer_len);

%typemap(in)        (uint8_t **data, size_t *len) = (void **arraybuffer_data, size_t *arraybuffer_len);
%typemap(argout)    (uint8_t **data, size_t *len) = (void **arraybuffer_data, size_t *arraybuffer_len);

// For Fill
%typemap(in)        uint8_t = int;

// Create an async version of Write
%feature("async:locking", "1");
%feature("async", "Async") Blob::Write;

%include <blob.h>
