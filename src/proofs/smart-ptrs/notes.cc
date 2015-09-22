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
