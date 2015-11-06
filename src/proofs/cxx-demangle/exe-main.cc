# include <exception>
# include <iostream>
# include <cxxabi.h>
# include <cstdint>

# define cast(t) (t)

namespace foo { struct slots_t { intptr_t fred; }; }

auto demangle(char const* mangled_name) -> char const* {
  int status = -1;
  char const* name = abi::__cxa_demangle(mangled_name, 0, 0, &status);
  if (0 == status)
    return name;
  else
    return nullptr;
}
static char const* name = demangle(typeid(foo::slots_t::fred).name());

int main() {
  printf("%s\n", demangle(typeid(foo::slots_t::fred).name()));
  return 0;
}
