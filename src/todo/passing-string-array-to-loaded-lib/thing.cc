#include <stdio.h>
#include <stdlib.h>

static __attribute__((constructor)) void init()
{
  const char* klses_str = getenv("DK_DUMP_KLSES");
  const char* const* klses;
  sscanf(klses_str, "%p", &klses);
  const char* kls;
  while (NULL != (kls = *klses++))
    printf("%s\n", kls);
  return;
}
