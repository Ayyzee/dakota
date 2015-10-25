// -*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

#include <stdio.h>
#include <limits>

int main() {
  printf("%i\n", std::numeric_limits<char>::is_signed);
  //printf("%i\n", std::numeric_limits<wchar_t>::is_signed);
  return 0;
}
