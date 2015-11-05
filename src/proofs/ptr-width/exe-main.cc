# include <cstdio>

# ifndef  __STDC_FORMAT_MACROS
# define  __STDC_FORMAT_MACROS
# endif //__STDC_FORMAT_MACROS
# include <inttypes.h>

const int ptr_width =  snprintf(nullptr, 0, "0x%" PRIxPTR, (uintptr_t)~0);

int main()
{
  // should be 10 (2 +  8) on 32 bit
  // should be 18 (2 + 16) on 64 bit

  printf("ptr_width=%i\n", ptr_width);
  return 0;
}
