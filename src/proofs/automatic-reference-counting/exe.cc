#include <iostream>
#include <memory>

namespace object { struct slots_t; }
namespace object { struct slots_t { object::slots_t* klass; }; }
//namespace dk { object::slots_t* dealloc(object::slots_t* self) { return nullptr; } }

typedef std::shared_ptr<object::slots_t> object_t;
static object_t bar(object_t self) { return self; }

int main() {
  std::size_t size = 256;
  auto ptr = static_cast<object::slots_t*>(operator new(size));
  auto deleter = [](object::slots_t* arg) { operator delete(static_cast<void*>(arg)); };
  object_t foo(ptr, deleter);

  printf("ptr=%p\n", ptr);
  printf("ptr->klass=%p\n", ptr->klass);
  printf("(*foo).klass=%p\n", (*foo).klass);
  printf("foo->klass=%p\n", foo->klass);

  bar(foo);
  
  return 0;
}
// static object::slots_t* object_alloc(std::size_t size) {
//   object::slots_t* ptr = static_cast<object::slots_t*>(operator new(size));
//   return ptr;
// }
// static void object_dealloc(object::slots_t* ptr) {
//   operator delete(ptr);
//   return;
// }
// static void* dkt_alloc(std::size_t size) {
//   void* ptr = operator new(size);
//   return ptr;
// }
// static void dkt_dealloc(object::slots_t* ptr) {
//   operator delete(ptr);
//   return;
// }
