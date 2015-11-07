# include <cstdio>

# define print(s) printf("%s: %s\n", # s, s)
# define symbolicate(a) _ ## a ## _

typedef char const* symbol_t;

static symbol_t dk_intern(char const* str) { return str; }

namespace __symbol {
  static symbol_t symbolicate(int) = dk_intern("int");
}
int main() {
  char const* str = "hello";
  print(str);

  return 0;
}
