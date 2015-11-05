# include <cstdlib>
# include <cxxabi.h>
# include <memory>

# include "typeinfo.hh"

# if defined __GNUG__
std::string demangle(const char* name) {
  int status = -1;
  std::unique_ptr<char, void(*)(void*)> res {
    abi::__cxa_demangle(name, NULL, NULL, &status), std::free
  };
  return (status == 0) ? res.get() : name;
}
# else // does nothing if not g++
std::string demangle(const char* name) {
  return name;
}
# endif
