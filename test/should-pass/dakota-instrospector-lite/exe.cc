// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/param.h> // MAXPATHLEN

int main(int argc, char** argv)
{
  int status = EXIT_SUCCESS;
  int overwrite;
  setenv("DK_INTROSPECTOR_OUTPUT", "", overwrite = 1);
  const char* arg = NULL;
  int i = 1;
  while (NULL != (arg = argv[i++]))
  {
    setenv("DK_INTROSPECTOR_ARG", arg, overwrite = 1);
    if (NULL == strchr(arg, '/'))
    { // not required on darwin (required on linux)
      char arg_path[MAXPATHLEN] = "";
      strcat(arg_path, "./");
      strcat(arg_path, arg);
      arg = arg_path;
    }
    void* handle = dlopen(arg, RTLD_NOW | RTLD_LOCAL);
    if (NULL == handle)
    {
      status = EXIT_FAILURE;
      fprintf(stderr, "ERROR: %s: \"%s\"\n", arg, dlerror());
    }
  }
  return status;
}
