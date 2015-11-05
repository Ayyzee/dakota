#include <cstdarg>
#include <iostream>
#include <memory>

typedef va_list va_list_t;

namespace object { struct slots_t; }
namespace object { struct slots_t { object::slots_t* klass; }; }
typedef std::shared_ptr<object::slots_t*> object_t;

namespace va { static auto func(object_t self, va_list_t args) -> object_t; }

static auto va::func(object_t /*self*/, va_list_t args) -> object_t {
  auto instance = va_arg(args, object_t);
  // ...
  return instance;
}
static auto func(object_t self, ...) -> object_t {
  va_list_t args;
  va_start(args, self);
  auto result = va::func(self, args);
  va_end(args);
  return result;
}
int main() {
  object_t self = nullptr;
  object_t instance = nullptr;
  object_t result = func(self, instance);
  return 0;
}
