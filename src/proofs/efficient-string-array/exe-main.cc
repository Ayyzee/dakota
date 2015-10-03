// -*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

#include <stdio.h>
#include <stdint.h>
#include <string.h>

struct tkns4x4_t { // 4 bits of total-len and 4 bits of num-strs
  char const *tkns;
};

struct tkns5x3_t { // 5 bits of total-len and 3 bits of num-strs
  char const *tkns;
};

//  01234567890123456789012345678901

int main()
{
  // - num of strings        (2^4 = 16)
  // - max len of all string (2^4 = 16)
  // - total len             (2^4 = 16)
  // one can only have 2 of the 3
  
  char const tkns[] = "char" "\0" "const" "\0" "*" "\0";

  for (int i = 0; i < sizeof(tkns); i++) {
    printf("%c (0x%x)\n", tkns[i], tkns[i]);
  }
  return 0;
}
