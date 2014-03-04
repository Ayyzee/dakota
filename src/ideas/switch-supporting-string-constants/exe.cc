#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>

#include <sys/time.h>

__attribute__((pure)) int test(const char* str);

#if 0
#define ECHO(s) printf(s)
#else
#define ECHO(s)
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
#if 1
  const char* strs[] =
    {
      // 14:6 (failures:successes)
      "a", "ab", "abc", "abcd", "abcde", "abcdef", "abcdefg", "abcdefgh", "abcdefghi", "abcdefghij",
      "j", "jk", "jkl", "jklm", "jklmn", "jklmno", "jklmnop", "jklmnopq", "jklmnopqr", "jklmnopqrs",
      NULL
    };
  uint32_t iters = 3 * 1024 * 1024;
#else
  const char* strs[] =
    {
      // 0:6 (failures:successes)
      "ab", "abcde", "abcdefghi",
      "jklm", "jklmnop", "jklmnopqr",
      NULL
    };
  uint32_t iters = 7 * 1024 * 1024;
#endif
  uint32_t equality_tests = 0;
  uint32_t failed_equality_tests = 0;

  struct timeval initial_tv = {0};
  gettimeofday(&initial_tv, NULL);

  for (uint32_t j = 0; j < iters; j++)
  {
    for (int i = 0; NULL != strs[i]; i++)
    {
      if (use_switch)
      {
        switch (test(strs[i]))
        {
          case 0: // "ab"
            ECHO("0\n");
            break;
          case 1: // "abcde"
            ECHO("1\n");
            break;
          case 2: // "abcdefghi"
            ECHO("2\n");
            break;
          case 3: // "jklm"
            ECHO("3\n");
            break;
          case 4: // "jklmnop"
            ECHO("4\n");
            break;
          case 5: // "jklmnopqr"
            ECHO("5\n");
            break;
          default:
            ECHO("-1\n");
            failed_equality_tests++;
        }
        equality_tests++;
      }
      else
      {
	if (0 == strcmp(strs[i], "ab"))
          ECHO("0\n");
        else if (0 == strcmp(strs[i], "abcde"))
          ECHO("1\n");
        else if (0 == strcmp(strs[i], "abcdefghi"))
          ECHO("2\n");
        else if (0 == strcmp(strs[i], "jklm"))
          ECHO("3\n");
        else if (0 == strcmp(strs[i], "jklmnop"))
          ECHO("4\n");
        else if (0 == strcmp(strs[i], "jklmnopqr"))
          ECHO("5\n");
        else
        {
          ECHO("-1\n");
          failed_equality_tests++;
        }
        equality_tests++;
      }
    }
  }
  struct timeval final_tv = {0};
  gettimeofday(&final_tv, NULL);

  time_t      sec = final_tv.tv_sec - initial_tv.tv_sec;
  suseconds_t usec;
  if (final_tv.tv_usec < initial_tv.tv_usec)
  {
    sec--;
    usec = 1000000 + final_tv.tv_usec - initial_tv.tv_usec;
  }
  else
    usec = final_tv.tv_usec - initial_tv.tv_usec;
  float duration = sec;
  duration +=  (float)usec/1000000;

#if 1
  int min = 1024;
  int max = 0;
  int cnt = 0;
  int ave = 0;
  for (int i = 0; NULL != strs[i]; i++)
  {
    int len = strlen(strs[i]);
    if (min > len)
      min = len;
    if (max < len)
      max = len;
    ave += len;
    cnt++;
  }
  ave /= cnt;
  fprintf(stderr, "min-len: %i, max-len: %i, ave-len: %i, failures/successes: %iM/%iM, duration: %f\n",
          min, max, ave,
          failed_equality_tests/(1024 * 1024),
          equality_tests/(1024 * 1024) - failed_equality_tests/(1024 * 1024),
          duration);
#endif
  exit(EXIT_SUCCESS);
}

#include "test.h" // generated
