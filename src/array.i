%include <std_vector.i>

%{
  // This goes into the wrapper code (header section)
  #include "array.h"
%}

// This applies the automatic conversion typemaps to those arguments
%apply(std::vector const &INPUT)      { std::vector const &in_data };
%apply(std::vector &OUTPUT)           { std::vector &out_data };
// and return values
%apply(std::vector RETURN)            { std::vector ReturnVector1 };

// ignore operator=
%ignore operator=;

// Bring in all the function definitions
%include <array.h>
