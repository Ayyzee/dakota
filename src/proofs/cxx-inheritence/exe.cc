// -*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

#include <stdio.h>

struct a_t {
  int a;
};
struct b_t : a_t {
  // a
  int b;
};
struct c_t : b_t {
  // a
  // b
  int c;
};
struct d_t {
  int d;
};
struct e_t {
  int e;
};
struct f_t : d_t, e_t {
  // d
  // e
  int f;
};
int main() {
  c_t c {};
  c.a = 0;
  c.b = 0;
  c.c = 0;

  f_t f {};
  f.d = 0;
  f.e = 0;
  f.f = 0;

  printf("sizeof(a_t)=%lu\n", sizeof(a_t));
  printf("sizeof(b_t)=%lu\n", sizeof(b_t));
  printf("sizeof(c_t)=%lu\n", sizeof(c_t));

  printf("sizeof(f_t)=%lu\n", sizeof(f_t));
  
  return 0;
}
