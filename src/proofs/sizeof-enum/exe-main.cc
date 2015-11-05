// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <stdio.h>

enum slots0_t
{
};

enum slots1_t
{
  k_first1,
};

enum slots2_t
{
  k_first2,
  k_second2,
};

enum slots3_t
{
  k_first3,
  k_second3,
  k_third3,
};

int main()
{
  printf("%lu\n", sizeof(slots0_t));
  printf("%lu\n", sizeof(slots1_t));
  printf("%lu\n", sizeof(slots2_t));
  printf("%lu\n", sizeof(slots3_t));
  return 0;
}
