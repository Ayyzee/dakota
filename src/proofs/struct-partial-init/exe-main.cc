// -*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

#include <stdio.h>

namespace file { typedef FILE* slots_t; }
typedef file::slots_t file_t;

int main()
{
  //  struct { bool state; file_t value; } length = { false, file_t(0) };
  struct { bool state; file_t value; } length = { 0 };
  return 0;
}
