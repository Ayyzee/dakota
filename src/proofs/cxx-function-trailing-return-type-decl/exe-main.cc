typedef auto cmp1_t(char const*, char const*) -> int;
// or
typedef auto (cmp4_t)(char const*, char const*) -> int;
// or
typedef int (*cmp2_t)(char const*, char const*);
// or
typedef auto (*cmp3_t)(char const*, char const*) -> int;

int cmp(char const*, char const*) { return -1; }

// all semantically equivalent
using cmp_t = int(char const*, char const*);
using cmp_t = auto(char const*, char const*) -> int;
typedef auto cmp_t(char const*, char const*) -> int;

int main() {
  cmp1_t* cmp1 = cmp;
  cmp1("", "");
  cmp4_t* cmp4 = cmp;
  cmp4("", "");

  cmp2_t cmp2 = cmp;
  cmp2("", "");
  cmp3_t cmp3 = cmp;
  cmp3("", "");

  return 0;
}
