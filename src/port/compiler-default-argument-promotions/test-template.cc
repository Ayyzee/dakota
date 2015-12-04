// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <cstdio>
# include <cstdarg>

# include "types.hh"

# define cast(t) (t)
# define USE(v) cast(void)v

namespace va { auto func(void*, va_list_t) -> void; }
auto func(void*, ...) -> void;

namespace va { auto func(void*, va_list_t args) -> void {
  __TYPE__ arg = va_arg(args, __TYPE__);
  USE(arg);
  return;
} }
auto func(void* self, ...) -> void {
  va_list_t args;
  va_start(args, self);
  va::func(self, args);
  va_end(args);
  return;
}
auto main() -> int_t {
  return 0;
}
