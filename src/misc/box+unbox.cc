// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

namespace object { struct slots_t; }
typedef object::slots_t* object_t;

namespace num
{
  typedef int slots_t;

  slots_t* unbox(object_t object)
  {
    return (slots_t*)0;
  }
  object_t box(slots_t* slots)
  {
    // bulk here
    return (object_t)0;
  }
  object_t box(slots_t slots)
  {
    object_t object = box(&slots);
    return object;
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

  slots_t* unbox(object_t object)
  {
    return (slots_t*)0;
  }
  object_t box(slots_t* slots)
  {
    // bulk here
    return (object_t)0;
  }
  object_t box(slots_t slots)
  {
    object_t object = box(&slots);
    return object;
  }
}
typedef point::slots_t point_t;

namespace str32
{
  typedef char slots_t[32];

  slots_t* unbox(object_t object)
  {
    return (slots_t*)0;
  }
  object_t box(slots_t* slots)
  {
    // bulk here
    return (object_t)0;
  }
  object_t box(slots_t slots)
  {
    object_t object = box((slots_t*)&slots);
    return object;
  }
}
typedef str32::slots_t str32_t;

int main()
{
  object_t o;

  str32_t s;
  o = str32::box(s);
  str32_t* t = str32::unbox(o);
  (void)t;

  point_t  p;
  o = box(p);
  p = *point::unbox(o);

  num_t n;
  o = num::box(n);
  n = *num::unbox(o);

  return 0;
}

// unbox(): same in all three cases
