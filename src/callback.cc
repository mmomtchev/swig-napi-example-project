#include "callback.h"

std::string GiveMeFive(std::function<std::string(int, const std::string &name)> giver) {
  return "received from JS: " + giver(420, "with cheese");
}
