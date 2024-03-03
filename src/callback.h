#include <string>
#include <functional>

std::string GiveMeFive(std::function<std::string(int, const std::string &)> giver);
std::string GiveMeFive_C(std::string (*giver)(void *, int, const std::string &), void *context);
