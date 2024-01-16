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

// Use the standard ArrayBuffer typemaps:
// * writable Buffer in an argument
%apply(void *arraybuffer_data, size_t arraybuffer_len)    {(uint8_t *data, size_t len)};

// * this one produces a returned value from the arguments
%apply(void **arraybuffer_data, size_t *arraybuffer_len)  {(uint8_t **data, size_t *len)};

// For Fill
%apply(int)                                               { uint8_t };

// Create an async version of Write
%feature("async:locking", "1");
%feature("async", "Async") Blob::Write;

%include <blob.h>
