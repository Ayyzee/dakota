// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

#include <stdint.h>

namespace object
{
  struct slots_t;
}
typedef object::slots_t* object_t;

namespace object
{
  struct slots_t
  {
    object_t klass;
  };
}

namespace point
{
  struct slots_t
  {
    int32_t x;
    int32_t y;
  };
}
typedef point::slots_t point_t;

static uintptr_t stuff[] = 
{
  0x0, 1, 3,
  0x0, 3, 5, 
};
