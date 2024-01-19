#include <vector>

// A class that holds an int
class IntObject {
  int value_;

public:
  IntObject(int value);
  int get() const;
};

// A method that takes a const std::vector of IntObjects
int ReadOnlyVector(const std::vector<IntObject> &IntObjects);

// A method that returns an std::vector of IntObjects
std::vector<IntObject> ReturnVector();
