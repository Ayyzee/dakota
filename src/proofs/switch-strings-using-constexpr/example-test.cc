// only C++11 and better

#include <cstdio>

//#include <dakota.hh>

#include "hash.hh"

int main(int argc, const char* const* argv) {
  for (int i = 1; i < argc; i++) {
    const char* str = argv[i];
    printf("0x%08x\n", dk_hash(str));
  }
  return 0;
}
