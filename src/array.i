#ifndef SWIG_JAVASCRIPT_EVOLUTION
#error blob requires SWIG JavaScript Evolution
#endif

%include <std_vector.i>

%{
  // This goes into the wrapper code
  #include "array.h"
%}

%apply(std::vector const &INPUT)      { std::vector const &in_data };
%apply(std::vector &OUTPUT)           { std::vector &out_data };
%apply(std::vector RETURN)            { std::vector ReturnVector1 };


// Bring in all the function definitions
%include <array.h>
