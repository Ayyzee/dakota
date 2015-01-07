// only C++11 and better

#include "hash.h"

int main(int argc, const char* const* argv)
{
  const char* str = "Value2";
  switch (dk_hash(str))
  {
    case dk_hash("Value1"):
      //
      break;
    case dk_hash("Value2"):
      //
      break;
    default:
      return 1;
  }
  return 0;
}
