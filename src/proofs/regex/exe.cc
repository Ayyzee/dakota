#include <regex>
#include <cstdio>

char const* cmatch_at(std::cmatch& m, std::regex e, size_t i, char const* file, unsigned int line, char const* dflt = "") {
  char const* result = dflt;
  if (i < m.size())
    result = m[i].str().c_str();
  else if (i >= e.mark_count())
    fprintf(stderr, "%s:%u: WARNING: $%zu is not a match group variable for the regex: xxx\n", file, line, i);
  return result;
}

int main() {
  char const* s = "this subject has a submarine as a subsequence";

  // while (s =~ m/\b(sub)([^ ]*)/g) {
  std::cmatch m; std::regex e("\\b(sub)([^ ]*)"); while (std::regex_search(s, m, e)) { s += (m.position() + m.length());

    // $0 => cmatch_at(m, e, 0, __FILE__, __LINE__)
    // $1 => cmatch_at(m, e, 1, __FILE__, __LINE__)
    // $2 => cmatch_at(m, e, 2, __FILE__, __LINE__)
    
    printf("size = %zu;\n", m.size());
    for (size_t i = 0; i < m.size(); i++) {
      printf("$%zu = \"%s\";\n", i, cmatch_at(m, e, i, __FILE__, __LINE__));
    }
    cmatch_at(m, e, 3, __FILE__, __LINE__);
  }
  return 0;
}
