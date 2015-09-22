#include <stdio.h>
#include <stdlib.h>
#include <dlfcn.h>

int main(int argc, const char* const* argv)
{
  char buf[2 + 16 + 1] = {0};
  snprintf(buf, sizeof(buf) - 1, "%p", &argv[2]);
  int overwrite;
  setenv("DK_DUMP_KLSES", buf, overwrite = 1);

  void* handle = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
  if (nullptr == handle)
    fprintf(stderr, "ERROR: %s: \"%s\"\n", argv[1], dlerror());
  return 0;
}
