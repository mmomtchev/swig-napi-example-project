#include "map.h"
#include <stdexcept>

void PutMap(std::map<std::string, std::string> &in_data) {
  if (in_data["expected"] != "value")
    throw new std::logic_error{"Did no't receive expected data"};
}

void GetMap(std::map<std::string, std::string> &out_data) {
  out_data["returned"] = "value";
}
