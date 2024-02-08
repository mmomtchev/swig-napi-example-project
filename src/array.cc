#include "array.h"

IntObject::IntObject(int value) : value_(value) {}
int IntObject::get() const {
  return value_;
};

int ReadOnlyVector(const std::vector<IntObject> &in_data) {
  return in_data[0].get();
}

std::vector<IntObject> ReturnVector1() {
  return {{1}, {2}, {3}};
}
void ReturnVector2(std::vector<IntObject> &out_data) {
  out_data = {{1}, {2}, {3}};
}
