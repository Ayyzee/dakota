#include <stdio.h>
#include <errno.h>
#include <string.h>

#define sc(n) if (-1 == ((int)n)) { fprintf(stderr, "%s:%i: error: errno=%i, \"%s\"\n", __FILE__, __LINE__, errno, strerror(errno)); }
