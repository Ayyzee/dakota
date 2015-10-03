#include <memory>
#include <cstdio>
#include <stdint.h>

template<T>
struct S
{
  uint32_t
};

int main() {
  printf("sizeof(void*)=%lu, "
         "sizeof(uintptr_t)=%lu, "
         "sizeof(instance)=%lu, "
         "sizeof(object_t)=%lu\n",
         sizeof(void*),
         sizeof(uintptr_t),
         sizeof(instance),
         sizeof(object_t));
  return 0;
}
