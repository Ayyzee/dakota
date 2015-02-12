#include <cstdio>

// keyword arguments
//   required (no RHS of =>)
//   optional

// emtpy set:   ${}
// empty table: ${:}

// method(object-t self, :foo:bar:thing-t thing   :other:thing) // incorrect
// method(object-t self, :foo:bar:thing-t thing : :other:thing) // correct

int foo()
{
  return {};
}

int main()
{
  printf("%i\n", foo());

  return 0;
}
