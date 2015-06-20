#include <iostream>
#include <memory>
#include <cstdarg>

typedef va_list va_list_t;

namespace object { struct slots_t; }
namespace object { struct slots_t { object::slots_t* klass; }; }
//namespace dk { object::slots_t* dealloc(object::slots_t* self) { return nullptr; } }

typedef std::shared_ptr<object::slots_t> object_t;

typedef object_t va_arg_object_t  __attribute__ ((aligned (sizeof(object_t))));

static object_t dummy(object_t self) { return self; }

namespace va { object_t func(object_t self, va_list_t args); }

object_t va::func(object_t /*self*/, va_list_t args) {
  object_t arg = va_arg(args, object_t);
  // ...
  return arg;
}
object_t func(object_t self, ...);
object_t func(object_t self, ...) {
  va_list_t args;
  va_start(args, self);
  object_t result = va::func(self, args);
  va_end(args);
  printf("%p\n", result); // debug
  return result;
}
object_t object_alloc(std::size_t size);
object_t object_alloc(std::size_t size) {
  auto ptr = static_cast<object::slots_t*>( operator new(size)    );
  auto deleter = [](object::slots_t* arg) { operator delete(arg); };
  object_t instance(ptr, deleter);
  return instance;
}

int main() {
  std::size_t size = 256;
  object_t instance = object_alloc(size);

  // printf("ptr=%p\n", ptr);
  // printf("ptr->klass=%p\n", ptr->klass);
  printf("sizeof(void*)=%lu, "
         "sizeof(uintptr_t)=%lu, "
         "sizeof(instance)=%lu, "
         "sizeof(object_t)=%lu\n",
         sizeof(void*),
         sizeof(uintptr_t),
         sizeof(instance),
         sizeof(object_t));
  printf("(*instance).klass=%p\n", (*instance).klass);
  printf("instance->klass=%p\n", instance->klass);

  dummy(instance);

  return 0;
}
