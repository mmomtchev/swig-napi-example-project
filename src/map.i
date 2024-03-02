// This enables the special std::string conversion maps
// Without it, SWIG will wrap the C++ std::string as any other type
%include <std_string.i>

%include <std_map.i>

%{
// This goes into the wrapper code
#include "map.h"
%}

// This applies the automatic conversion typemaps to those arguments
%apply(std::map const &INPUT)     { std::map &in_data };
%apply(std::map &OUTPUT)          { std::map &out_data };

// Bring in all the function definitions
%include <map.h>
