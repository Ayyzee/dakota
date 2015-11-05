// -*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <stdio.h>
# include <stdint.h>

# define cast(t) (t)

int main()
{
  struct { bool state; uint32_t value; } capacity = { false, cast(decltype(capacity.value))0 };

  decltype(capacity.value) foo = 0;
  return 0;
}
