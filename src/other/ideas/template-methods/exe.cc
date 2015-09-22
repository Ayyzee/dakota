#include <stdio.h>
#include <stdint.h>

template <typename t> t t_max(t a, t b)
{
  if (a >= b)
    return a;
  return b;
}

namespace int32 // klass int32
{
  typedef int32_t slots_t; // slots int32_t;
  static slots_t (*max)(slots_t self, slots_t other) =
    (slots_t (*)(slots_t, slots_t))t_max;
}
namespace uint32 // klass uint32
{
  typedef uint32_t slots_t; // slots uint32_t;
  static slots_t (*max)(slots_t self, slots_t other) =
    (slots_t (*)(slots_t, slots_t))t_max;
}

int main()
{
  {
  int32_t x = 3;
  int32_t y = 5;
  int32_t z = int32::max(x, y);
  printf("z = %i\n", z);
  }
  {
  uint32_t x = 7;
  uint32_t y = 5;
  uint32_t z = uint32::max(x, y);
  printf("z = %u\n", z);
  }
  return 0;
}
