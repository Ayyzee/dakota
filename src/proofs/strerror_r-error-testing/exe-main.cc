// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <errno.h>
# include <string.h>
# include <stdio.h>

// errnum []
// errnum []     && buf-too-small
// errnum ==   0
// errnum ==   0 && buf-too-small
// errnum >  max
// errnum >  max && buf-too-small

auto main() -> int {
  printf("EINVAL=%i\n", EINVAL);
  printf("ERANGE=%i\n", ERANGE);

  char buf[64]; buf[0] = '\0';
  size_t buflen;
  int rtn;
  int errnum;

  buf[0] = '\0'; errnum = 42; buflen = 0;
  rtn = strerror_r(errnum, buf, buflen);
  printf("rtn=%2i, errnum=%3i, buflen=%2zu, buf=\"%s\"\n", rtn, errnum, buflen, buf);

  buf[0] = '\0'; errnum = 0; buflen = sizeof(buf);
  rtn = strerror_r(errnum, buf, buflen); // this returns 0 even though errnum = 0 (this should have failed)
  printf("rtn=%2i, errnum=%3i, buflen=%2zu, buf=\"%s\"\n", rtn, errnum, buflen, buf);

  buf[0] = '\0'; errnum = 0; buflen = 0;
  rtn = strerror_r(errnum, buf, buflen);
  printf("rtn=%2i, errnum=%3i, buflen=%2zu, buf=\"%s\"\n", rtn, errnum, buflen, buf);

  buf[0] = '\0'; errnum = 999; buflen = sizeof(buf);
  rtn = strerror_r(errnum, buf, buflen);
  printf("rtn=%2i, errnum=%3i, buflen=%2zu, buf=\"%s\"\n", rtn, errnum, buflen, buf);

  buf[0] = '\0'; errnum = 999; buflen = 0;
  rtn = strerror_r(errnum, buf, buflen);
  printf("rtn=%2i, errnum=%3i, buflen=%2zu, buf=\"%s\"\n", rtn, errnum, buflen, buf);

  return 0;
}
