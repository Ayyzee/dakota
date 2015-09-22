// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

#include <string.h>

namespace object { struct slots_t; }
typedef object::slots_t* object_t;

namespace num
{
  typedef int slots_t;

  const slots_t* unbox(object_t object)
  {
    return (const slots_t*)0;
  }
}
typedef num::slots_t num_t;

namespace point
{
  struct slots_t
  {
    int x;
    int y;
  };

  const slots_t* unbox(object_t object)
  {
    return (const slots_t*)0;
  }
}
typedef point::slots_t point_t;

namespace str32
{
  typedef char slots_t[32];

  const slots_t* unbox(object_t object)
  {
    return (const slots_t*)0;
  }
}
typedef str32::slots_t str32_t;

int main()
{
  object_t o;

  const str32_t* t = str32::unbox(o);
  strcpy(*t, "");

  const point_t* pp = point::unbox(o);
  *pp = (point_t){0,0};

  const num_t* np = num::unbox(o);
  *np = 0;

  return 0;
}

// unbox(): same in all three cases
