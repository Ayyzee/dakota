#include <stdint.h>
#include <inttypes.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>

#define STR(s) (s + 4)
#define FF_STR(s) ("0005" s + 4)

uint16_t ff_strlen(const char* str)
{
  uint32_t len = strlen(str);
  char ff[4 + 1] = { *(str - (4 - 0)),
		     *(str - (4 - 1)),
		     *(str - (4 - 2)),
		     *(str - (4 - 3)),
		     0 };
  uint16_t ff_len = (uint16_t)strtoumax(ff, NULL, 16);
  assert(ff_len == len);
  return ff_len;
}

// char* ff_strcat(char* ff_buf, const char* str)
// {
  
// }

int main()
{
  {
    const char* ff_str = FF_STR("hello");
    printf("%s: %i\n", ff_str, ff_strlen(ff_str));
  }
  {
    const char* str = STR("0005hello");
    printf("%s: %i\n", str, (int16_t)strlen(str));
  }
  return 0;
}
