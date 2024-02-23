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

// Examples for handling callbacks
%include <callback.i>

// Allow JavaScript to check if async is enabled
%inline { extern const bool asyncEnabled; }
#ifdef NO_ASYNC
%wrapper { const bool asyncEnabled = false; }
#else
%wrapper { const bool asyncEnabled = true; }
#endif


// Because of https://github.com/mmomtchev/swig/issues/23
#if SWIG_VERSION < 0x050002
#error Generating this project requires SWIG JSE 5.0.2
#endif
%{
// Because of https://github.com/emscripten-core/emscripten/pull/21041
#ifdef __EMSCRIPTEN__
#include <emscripten/version.h>
#if __EMSCRIPTEN_major__ < 3 || (__EMSCRIPTEN_major__ == 3 && __EMSCRIPTEN_minor__ < 1) || (__EMSCRIPTEN_major__ == 3 && __EMSCRIPTEN_minor__ == 1 && __EMSCRIPTEN_tiny__ < 52)
#error Building this project requires emscripten 3.1.52
#endif
#endif
%}
