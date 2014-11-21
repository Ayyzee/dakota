#include <cstdlib>
#include <stdint.h>

#define cast(t) (t)

namespace object { struct slots_t { }; }
typedef object::slots_t* object_t;

namespace int32 { typedef int32_t slots_t; object_t box(slots_t s) { return nullptr; /*test hack*/ } }
using int32::box;

namespace assoc { struct slots_t { object_t key; object_t element; }; object_t box(slots_t s) { return nullptr; /*test hack*/ } }

void foo(object_t object, ...)
{
  return;
}

void bar(object_t object, ...)
{
  return;
}

namespace __keyword { const uint32_t _items = 0x12345678; }

/**
   insert cast(object_t[]) between => and {
   box each item iff not already boxed
   add terminated nullptr iff its not already terminated
   then rewrite the keyword argument syntax
 **/

int main()
{
  object_t o = nullptr;

//foo(o, items => { 1, 2 });
//gets rewritten to
  foo(o, __keyword::_items, cast(object_t[]){ box(1), box(2), nullptr }, nullptr);

  int32_t fred =  0;
  int32_t wilma = 1;

//bar(o, items => { fred => 1, wilma => 2 });
//gets rewritten to
  bar(o, __keyword::_items, cast(object_t[]){
      assoc::box(cast(assoc::slots_t){box(fred ), box(1)}),
      assoc::box(cast(assoc::slots_t){box(wilma), box(2)}),
        nullptr }, nullptr);

  return 0;
}
