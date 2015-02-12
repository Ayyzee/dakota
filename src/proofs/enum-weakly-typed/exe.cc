// -*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

#include <cstdio>

enum one_t { one_zero = 0 };
enum two_t { two_zero = 0 };

int main() {
  if (one_zero == two_zero) { // generates a warning
  }
  return 0;
}
