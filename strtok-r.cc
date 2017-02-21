// -*- mode: c++ -*-

# include <cassert>
# include <cstring>
# include <cstdio>
# include <memory>

# define cast(t) (t)
# define NUL cast(char)0

static auto substr_convert(char* str, const char* delims) -> int {
  assert(str != nullptr);
  assert(delims != nullptr && delims[0] != NUL);
  int len = 0;
  for (int i = 0; str[i]; i++) {
    int d;
    const char* p = delims;
    while ((d = *p++))
      if (str[i] == d)
        str[i] = NUL;
    len = 1 + i + 1;
  }
# if 1
  for (int j = 0; j < len; j++)
    printf("%c", str[j]);
  printf("\n");
# endif
  return len;
}
static auto substr(const char** strp, int* lenp) -> const char* {
  assert(strp != nullptr);
  assert(*strp != nullptr);
  const char* str = *strp;
  if (*lenp == -1)
    *lenp = cast(int)strlen(*strp);
  for (int i = 0; i < *lenp; i++) {
    if (str[i] != NUL) {
      int sslen = cast(int)strlen(str + i);
      *strp = *strp + i + sslen + 1;
      *lenp -= (i + sslen + 1);
      return str + i;
    }
  }
  return nullptr;
}
auto main(int, const char* const* argv) -> int {
  int c = 1;
  const char* ro_klss;
  while ((ro_klss = argv[c++])) {
    // 1:
    int l = cast(int)strlen(ro_klss) + (1);
    char klss[l + 1];
    strcpy(klss, ro_klss);
    klss[l] = NUL;
    // 2:
    int len = substr_convert(klss, ", ");
    // 3:
    const char* ss;
    const char* str = klss;
    while ((ss = substr(&str, &len))) {
      printf("%s\n", ss);
    }
  }
  return 0;
}
// clang++ -std=c++14 --warn-everything --warn-no-c99-extensions --warn-no-vla --warn-no-vla-extension --warn-no-c++98-compat --warn-no-old-style-cast -fsanitize=address --output strtok-r strtok-r.cc
