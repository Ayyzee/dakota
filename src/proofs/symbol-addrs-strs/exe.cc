#include <cstddef>
#include <cstdio>
#include <cstdlib>
#include <cassert>
#include <cstring>

#include <unistd.h>
#include <errno.h>

#include <sys/mman.h>
#include <mach-o/ldsyms.h>
#include <mach-o/getsect.h>

#define COUNTOF(a) (sizeof(a)/sizeof(a[0]))
#define noexport        __attribute__((__visibility__("hidden")))
#define symbols_section __attribute__((__section__("__DATA, __symbols")))
#define page_align      __attribute__ ((__aligned__(__pagesize)))
#define cast(t) (t)

#define tst(expr) if (expr) { fprintf(stderr, "errno: %i, str-errno: %s\n", errno, strerror(errno)); }
#define sc(i) tst(0 != i)

noexport const size_t __pagesize = 4096;

typedef char const* symbol_t;

template <typename T, size_t N>
constexpr size_t countof(T(&)[N]) {
  return N;
}
namespace __symbol {
  extern noexport symbol_t _first;
  // ...
  extern noexport symbol_t _last;
}
namespace __symbol {
  noexport symbols_section symbol_t _first page_align;
  // ...
  noexport symbols_section symbol_t _last;
}
static symbol_t* const symbol_addrs[] = { // read-write
  &__symbol::_first,
  // ...
  &__symbol::_last,
};
static char const* const symbol_strs[] = { // read-only
  "first",
  // ...
  "last",
};
static_assert(COUNTOF(symbol_addrs) == COUNTOF(symbol_strs), "symbol_addrs and symbol_strs must be same len");
symbol_t dk_intern(char const* str);
symbol_t dk_intern(char const* str) {
  return str;
}
void dk_intern(symbol_t* const addrs[], char const* const strs[], unsigned int len);
void dk_intern(symbol_t* const addrs[], char const* const strs[], unsigned int len) {
  for (unsigned int i = 0; i < len; i++) {
    *(addrs[i]) = dk_intern(strs[i]);
  }
  return;
}
// darwin: getsectiondata() and mprotect()
// linux:  elf_getdata()    and mprotect()

extern noexport const struct mach_header_64 * __mh_header;
noexport const struct mach_header_64 * __mh_header = &_mh_execute_header;

int set_read_only(char const* segment, char const* section);
int set_read_only(char const* segment, char const* section) {
  assert(NULL != segment);
  assert(NULL != section);
  assert(getpagesize() == __pagesize);
  
  unsigned long size = 0;
  uint8_t* addr = getsectiondata(__mh_header, segment, section, &size);
  int result = -1;
  if (NULL != addr) {
    result = mprotect(cast(void*)addr, size, PROT_READ);
  }
  return result;
}
int main() {
  dk_intern(symbol_addrs, symbol_strs, sizeof(symbol_addrs)/sizeof(symbol_strs));
  int e = set_read_only("__DATA", "__symbols"); sc(e);
  __symbol::_first = "should-not-work";
 return 0;
}
