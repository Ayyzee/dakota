#include <stdio.h>

static int count = 0;

__attribute__((constructor))
static
void dk_runtime_initialize()
{
     fprintf(stderr, "%s(), count=%i\n", __func__, count);
     return;
}

__attribute__((destructor))
static
void dk_runtime_finalize()
{
     fprintf(stderr, "%s(), count=%i\n", __func__, count);
     return;
}

void
dk_register(const char* lib_name)
{
     count++;
     fprintf(stderr, "%s(\"%s\"), count=%i\n", __func__, lib_name, count);
     return;
}

void
dk_unregister(const char* lib_name)
{
     fprintf(stderr, "%s(\"%s\"), count=%i\n", __func__, lib_name, count);
     count--;
     return;
}
