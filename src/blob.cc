#include "blob.h"
#include <string.h>
#include <stdexcept>

Blob::Blob() : data_(nullptr), len_(0) {}

Blob::Blob(size_t len) : len_(len) {
  data_ = new uint8_t[len_];
}

Blob::Blob(uint8_t *data, size_t len) : len_(len) {
  data_ = new uint8_t[len_];
  memcpy(data_, data, len_);
}

Blob::Blob(const Blob &other) : Blob(other.data_, other.len_) {}

void Blob::Fill(uint8_t value) {
  memset(data_, value, len_);
}

void Blob::Export(uint8_t **data, size_t *len) {
  *data = new uint8_t[len_];
  memcpy(*data, data_, len_);
  *len = len_;
}

void Blob::Write(uint8_t *data, size_t len) {
  if (len != len_) throw std::logic_error{"Sizes must match"};
  memcpy(data, data_, len_);
}

Blob::~Blob() {
  delete [] data_;
}
