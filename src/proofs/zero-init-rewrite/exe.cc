#include <stdio.h>
#include <assert.h>

#define cast(t) (t)

int main()
{
//int foo1 = zero;
//=>
  int foo1 = cast(decltype(foo1))0;

//struct { int x; int y; } foo2 = zero;
//=>
//struct { int x; int y; } foo2 = { zero, zero };
//=>
  struct { int x; int y; } foo2 = { cast(decltype(foo2.x))0, cast(decltype(foo2.x))0 };

  return 0;
}
