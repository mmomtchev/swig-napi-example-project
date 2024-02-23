#include "callback.h"

std::string GiveMeFive(std::function<std::string(int)> giver) {
  return "received from JS: " + giver(420);
}
