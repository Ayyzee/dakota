#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "duration.h"
#include "mph.h"

#include "rn--mph_00.h" // generated

static unsigned int time_test(const mph_t* mph, const char* str)
{
  unsigned int result;
  struct timeval tv1 = {0};
  struct timeval tv2 = {0};
  uint32_t iters = 64 * 1024 * 1024;

  gettimeofday(&tv1, nullptr);
  for (uint32_t j = 0; j < iters; j++) {
    result = mph->hash(str);
  }
  gettimeofday(&tv2, nullptr);

  float dur = duration(tv1, tv2);
  const char* result_str = mph::str(mph, result);
  printf("%u: %f: \"%s\": \"%s\"\n", result, dur, str, result_str);
  return result;
}

int main(int argc, char** argv)
{
  const mph_t* mph = &rn::mph_00;

  time_test(mph, nullptr);
  time_test(mph, "");

  for (unsigned int i = 0; i < mph->strs_len; i++) {
    const char* str = mph->strs[i];
    time_test(mph, str);
  }
  exit(EXIT_SUCCESS);
}
