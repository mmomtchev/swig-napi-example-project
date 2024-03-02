#include <string>
#include <functional>

std::string GiveMeFive(std::function<std::string(int, const std::string &)> giver);
