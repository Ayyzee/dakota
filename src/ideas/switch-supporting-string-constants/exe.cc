#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>

#include "duration.h"
#include "mph.h"

#include "rn--mph_00.h" // generated

#if 0
#define ECHO(f, ...) printf(f, __VA_ARGS__)
#else
#define ECHO(f, ...)
#endif


int main(int argc, char** argv)
{
  if (2 != argc)
    exit(EXIT_FAILURE);
  int use_switch;
  if (0 == strcmp("0", argv[1]))
    use_switch = 0;
  else if (0 == strcmp("1", argv[1]))
    use_switch = 1;
  else
    exit(EXIT_FAILURE);

  uint32_t iters = 3 * 1024 * 1024;
  uint32_t equality_tests = 0;
  uint32_t failed_equality_tests = 0;

  int min = 1024;
  int max = 0;
  int cnt = 0;
  int ave = 0;
  const mph_t* mph = &rn::mph_00;

  struct timeval initial_tv = {0};
  gettimeofday(&initial_tv, NULL);

  const size_t width = 32;
  char str[width] = "";
  while (EOF != fscanf(stdin, "%s", str)) {
    int len = strlen(str);
    if (min > len)
      min = len;
    if (max < len)
      max = len;
    ave += len;
    cnt++;

    for (uint32_t j = 0; j < iters; j++) {
      equality_tests++;

      if (use_switch) {
	unsigned int val;
	if (mph->fail != (val = mph->hash(str))) {
	  ECHO("%u\n", val);
	}
	else {
	  ECHO("%u\n", mph->fail);
          failed_equality_tests++;
	}
      }
      else {
	bool success = false;
	for (unsigned int k = 0; k < mph->strs_len; k++) {
	  const char* str2 = mph->strs[k];
	  if (0 == strcmp(str, str2)) {
	    ECHO("%u\n", mph->base + k);
	    success = true;
	    break;
	  }
	}
	if (!success) {
	  ECHO("%u\n", mph->fail);
          failed_equality_tests++;
	}
      }
    }
  }
  struct timeval final_tv = {0};
  gettimeofday(&final_tv, NULL);

  float dur = duration(initial_tv, final_tv);

#if 1
  ave /= cnt;
  fprintf(stderr, "min-len: %i, max-len: %i, ave-len: %i, failures/successes: %iM/%iM, duration: %f\n",
          min, max, ave,
          failed_equality_tests/(1024 * 1024),
          equality_tests/(1024 * 1024) - failed_equality_tests/(1024 * 1024),
          dur);
#endif
  exit(EXIT_SUCCESS);
}
