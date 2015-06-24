#include <iostream>
#include <memory>
#include <cstdarg>

#define cast(t) (t)

typedef va_list va_list_t;

namespace object { struct slots_t; }
namespace object { struct slots_t { object::slots_t* klass; }; }
typedef std::shared_ptr<object::slots_t> object_t;

#if 0
struct pod_object_t { void* p1; void* p2; };

namespace va { object_t func(object_t self, va_list_t args); }

object_t va::func(object_t /*self*/, va_list_t args) {
  object_t arg = cast(object_t)va_arg(args, pod_object_t);
  // ...
  return arg;
}
object_t func(object_t self, ...);
object_t func(object_t self, ...) {
  va_list_t args;
  va_start(args, self);
  auto result = va::func(self, args);
  va_end(args);
  return result;
}
#endif
object_t object_create(std::size_t size);
object_t object_create(std::size_t size) {
  auto ptr = static_cast<object::slots_t*>( operator new(size)    );
  auto deleter = [](object::slots_t* arg) { operator delete(arg); };
  object_t instance(ptr, deleter);
  return instance;
}
int main() {
  std::size_t size = 256;
  object_t instance = object_create(size);
  // object_t self = nullptr;
  // object_t result = func(self, cast(pod_object_t)(instance);

  printf("sizeof(void*)=%lu, "
         "sizeof(uintptr_t)=%lu, "
         "sizeof(object_t)=%lu, "
         "sizeof(instance)=%lu, "
         // "sizeof(result)=%lu, "
         "\n",
         sizeof(void*),
         sizeof(uintptr_t),
         sizeof(object_t),
         sizeof(instance)
         // sizeof(result),
         );
  printf("(*instance).klass=%p\n", (*instance).klass);
  printf("instance->klass=%p\n", instance->klass);
  return 0;
}
