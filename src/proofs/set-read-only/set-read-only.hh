#include <cstdlib>
#include <cstddef>
#include <cstdio>
#include <cassert>
#include <cstring>

#include <unistd.h>
#include <errno.h>

#include <dlfcn.h>

#include <sys/mman.h>
#include <mach-o/ldsyms.h>
#include <mach-o/getsect.h>


#define COUNTOF(a) (sizeof(a)/sizeof(a[0]))
#define noexport        __attribute__((__visibility__("hidden")))
#define symbols_section __attribute__((__section__("__dk_readonly" ", " "__dk_readonly")))
#define page_align      __attribute__((__aligned__(__pagesize)))
#define cast(t) (t)

#define tst(expr) if (expr) { fprintf(stderr, "errno: %i, str-errno: %s\n", errno, strerror(errno)); }
#define sc(i) tst(0 != i)

noexport const size_t __pagesize = 4096;

template <typename T, size_t N>
constexpr size_t countof(T(&)[N]) {
  return N;
}
typedef char const* symbol_t;

extern symbol_t* const symbol_addrs[];
extern char const* const symbol_strs[];
extern size_t symbol_len;

symbol_t dk_intern(char const* str);
void dk_intern(symbol_t* const addrs[], char const* const strs[], size_t len);
int set_read_only(char const* segment);

namespace __symbol {
  extern symbol_t _first;
  // ...
  extern symbol_t _last;
}
