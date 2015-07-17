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
#define symbols_section __attribute__((__section__("__dk_readonly" ", " "__dk_readonly")))
#define page_align      __attribute__((__aligned__(__pagesize)))
#define cast(t) (t)

#define tst(expr) if (expr) { fprintf(stderr, "errno: %i, str-errno: %s\n", errno, strerror(errno)); }
#define sc(i) tst(0 != i)

const size_t __pagesize = 4096;

template <typename T, size_t N>
constexpr size_t countof(T(&)[N]) {
  return N;
}
typedef char char8_t;
typedef char8_t const* symbol_t;
typedef unsigned int uint_t;
typedef unsigned long int ulint_t;
typedef int int_t;


extern symbol_t* const symbol_addrs[];
extern char8_t const* const symbol_strs[];
extern size_t symbol_len;

symbol_t dk_intern(char8_t const* str);
void dk_intern(symbol_t* const addrs[], char8_t const* const strs[], size_t len);
int_t set_read_only(char8_t const* segment);

namespace __symbol {
  extern symbol_t _first;
  // ...
  extern symbol_t _last;
}
