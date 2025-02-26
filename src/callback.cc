#include "callback.h"

std::string GiveMeFive(std::function<std::string(int, const std::string &)> giver) {
  return "received from JS: " + giver(420, "with cheese");
}

std::string GiveMeFive_C(std::string (*giver)(void *, int, const std::string &), void *context) {
  return "received from JS: " + giver(context, 420, "with extra cheese");
}

void JustCall(std::function<void()> cb) {
  cb();
}
