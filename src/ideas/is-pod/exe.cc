#include <stdio.h> // printf()

// __is_pod
#if 1
  #include "algorithm.h"
#else
  #include <algorithm>
#endif

struct point1_t
{ int x; int y; };

struct point2_t
{ int x; int y; point2_t(int x, int y){ this->x = x; this->y = y; } };

int main()
{
  int i;
  i = std::__is_pod<point1_t>::__value;
  printf("%i\n", i);
  i = std::__is_pod<point2_t>::__value;
  printf("%i\n", i);
  return 0;
}
