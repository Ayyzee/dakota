#include <iostream>
#include <memory>
#include <cstdarg>

typedef va_list va_list_t;

struct ptr_pair_t {
  void* p1;
  void* p2;
};
namespace va { ptr_pair_t func(void* /*self*/, va_list_t args); }
namespace va { ptr_pair_t func(void* /*self*/, va_list_t args) {
  ptr_pair_t arg = va_arg(args, decltype(arg));
  // ...
  return arg;
}}
ptr_pair_t func(void* self, ...);
ptr_pair_t func(void* self, ...) {
  va_list_t args;
  va_start(args, self);
  auto result = va::func(self, args);
  va_end(args);
  return result;
}
int main() {
  void* self = nullptr;
  ptr_pair_t ptr_pair = { nullptr, nullptr };
  func(self, ptr_pair);

  printf("sizeof(ptr_pair_t)=%lu, sizeof(std::shared_ptr<void*>)=%lu\n",
         sizeof(ptr_pair_t), sizeof(std::shared_ptr<void*>));

  return 0;
}
