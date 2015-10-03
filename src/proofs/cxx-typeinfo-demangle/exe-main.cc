#include <iostream>
#include <stdint.h>

#include "typeinfo.hh"
#include "typeinfo.cc"

namespace foo {
  struct slots_t {
  };
}
typedef foo::slots_t foo_t;
typedef int32_t myint_t;

int main() {
  foo_t foo;
  std::cout << typeid(foo).name() << std::endl;
  std::cout << demangle(typeid(foo).name()) << std::endl;

  myint_t x;
  std::cout << typeid(x).name() << std::endl;
  std::cout << demangle(typeid(x).name()) << std::endl;

  return 0;
}
