# line 1 "finally.dk"
// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <stdio.h>

int-t main()
{
  printf("%i\n", __LINE__);
  { try
  {
    printf("%i\n", __LINE__);
  }
  catch (...)
  {
    printf("%i\n", __LINE__);
  }
  struct finally_t { ~finally_t()
  {
    printf("%i\n", __LINE__);
  }} finally; }
  return 0;
}
