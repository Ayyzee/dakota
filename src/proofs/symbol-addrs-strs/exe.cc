#define ALEN(a) (sizeof(a)/sizeof(a[0]))
#define noexport __attribute__((__visibility__("hidden")))

typedef char const* symbol_t;

namespace __symbol {
  extern noexport symbol_t _first;
  extern noexport symbol_t _last;
}
namespace __symbol {
  noexport symbol_t _first;
  noexport symbol_t _last;
}
#define CONST const
static symbol_t CONST* const symbol_addrs[] = { // read-write
  &__symbol::_first,
  &__symbol::_last,
};
static char const* const symbol_strs[] = { // read-only
  "first",
  "last",
};
static_assert(ALEN(symbol_addrs) == ALEN(symbol_strs), "symbol_addrs and symbol_strs must be same len");
symbol_t dk_intern(char const* str);
symbol_t dk_intern(char const* str) {
  return str;
}
void dk_intern(symbol_t CONST* const addrs[], char const* const strs[], unsigned int len);
void dk_intern(symbol_t CONST* const addrs[], char const* const strs[], unsigned int len) {
  for (unsigned int i = 0; i < len; i++) {
    *(addrs[i]) = dk_intern(strs[i]);
  }
  return;
}
int main() {
  dk_intern(symbol_addrs, symbol_strs, sizeof(symbol_addrs)/sizeof(symbol_strs));
  return 0;
}
