# include <stdlib.h>

int main() {
  char *buffer;
  int pagesize;

  pagesize = sysconf(_SC_PAGE_SIZE);
  if (pagesize == -1) handle_error("sysconf");

  if (posix_memalign((void **)&buffer, pagesize, 4 * pagesize) != 0) {
    handle_error("posix_memalign");
  }
  return 0;
}

