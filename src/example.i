%module example

#ifndef SWIG_JAVASCRIPT_EVOLUTION
#error This project requires SWIG JavaScript Evolution
#endif

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

// Examples for handling binary data (uint8_t to ArrayBuffer)
%include <blob.i>

// Examples for handling arrays (std::vector to Array)
%include <array.i>

// Examples for handling objects (std::map to object)
%include <map.i>
