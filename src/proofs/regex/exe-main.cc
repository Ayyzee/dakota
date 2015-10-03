#include <regex>
#include <cstdio>

char const* cmatch_at(std::cmatch& m, std::regex& e, size_t i, char const* file, unsigned int line, char const* dflt = "");
char const* cmatch_at(std::cmatch& m, std::regex& e, size_t i, char const* file, unsigned int line, char const* dflt) {
  char const* result = dflt;
  if (i < m.size())
    result = m[i].str().c_str();
  else if (i >= e.mark_count())
    fprintf(stderr, "%s:%u: WARNING: $%zu is not a capture group variable for the regex: xxx\n", file, line, i);
  return result;
}

int main() {
  char const* s = "this subject has a submarine as a subsequence";
  printf("%s\n", s);
  {
  // MATCH: while (s =~ m/\b(sub)([^ ]*)/g) {
  char const* p = s; std::cmatch m; std::regex e("\\b(sub)([^ ]*)"); while (std::regex_search(p += (m.position() + m.length()), m, e)) {

    // $0 => cmatch_at(m, e, 0, __FILE__, __LINE__)
    // $1 => cmatch_at(m, e, 1, __FILE__, __LINE__)
    // $2 => cmatch_at(m, e, 2, __FILE__, __LINE__)
    
    printf("size = %zu;\n", m.size());
    for (size_t i = 0; i < m.size(); i++) {
      printf("$%zu = \"%s\";\n", i, cmatch_at(m, e, i, __FILE__, __LINE__));
    }
    cmatch_at(m, e, m.size(), __FILE__, __LINE__); // will produce warning on stderr
  }
  }
  {
  // SUBSTITUTE: s =~ /\b(sub)([^ ]*)/$1-$2/
#if 1
  std::regex e("\\b(sub)([^ ]*)"); s = std::regex_replace(s, e, "$1-$2").c_str();
#else
  s = std::regex_replace(s, std::regex("\\b(sub)([^ ]*)"), "$1-$2").c_str();
#endif
  }
  printf("%s\n", s);
  return 0;
}
