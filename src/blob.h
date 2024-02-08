/* This is the class that will be exported to JavaScript and TypeScript */
#include <cstddef>
#include <cstdint>

class Blob {
  uint8_t *data_;
  size_t len_;

public:
  // Create an null blob
  Blob();

  // Create an empty blob
  Blob(size_t len);

  // Create a new blob copying the data
  Blob(uint8_t *data, size_t len);

  // Copy a blob
  Blob(const Blob &other);

  // Fill a blob
  void Fill(uint8_t value);

  // Export a blob in a new ArrayBuffer
  void Export(uint8_t **data, size_t *len);

  // Write a blob to an existing ArrayBuffer
  void Write(uint8_t *data, size_t len);

  virtual ~Blob();
};
