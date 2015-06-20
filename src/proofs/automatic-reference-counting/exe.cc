#include <iostream>
#include <memory>

namespace object { struct slots_t; }
namespace object { struct slots_t { object::slots_t* klass; }; }
//namespace dk { object::slots_t* dealloc(object::slots_t* self) { return nullptr; } }

static std::shared_ptr<object::slots_t> bar(std::shared_ptr<object::slots_t> self) { return self; }

int main() {
  auto ptr = static_cast<object::slots_t*>(operator new(256));
  auto deleter = [](object::slots_t* arg) { operator delete(arg); };
  std::shared_ptr<object::slots_t> foo(ptr, deleter);

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
