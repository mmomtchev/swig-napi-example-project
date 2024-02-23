%{
  // This goes into the wrapper code (header section)
  #include "blob.h"
%}

%include <arraybuffer.i>

%apply(unsigned)                                          { size_t };

// Use the standard ArrayBuffer typemaps:
// * writable Buffer in an argument
%apply(void *arraybuffer_data, size_t arraybuffer_len)    { (uint8_t *data, size_t len) };

// * this one produces a returned value from the arguments
%apply(void **arraybuffer_data, size_t *arraybuffer_len)  { (uint8_t **data, size_t *len) };
%typemap(freearg, noblock=1) (uint8_t **data, size_t *len) "delete[] *$1;"

// For Fill
%apply(int)                                               { uint8_t };

#ifndef NO_ASYNC
// Prevent objects (and references) of type Blob from being reentered when using async
%feature("async:locking", "1");
%apply(SWIGTYPE LOCK)                                     { Blob };
%apply(SWIGTYPE &LOCK)                                    { Blob & };
// Create an async version of Write
%feature("async", "Async") Blob::Write;
#endif

// Bring in all the function definitions
%include <blob.h>
