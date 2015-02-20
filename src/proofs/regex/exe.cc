#include <regex>
#include <cstdio>

int main()
{
  char const* s = "this subject has a submarine as a subsequence";

  std::cmatch m;
  std::regex e("\\b(sub)([^ ]*)");

  while (std::regex_search(s, m, e)) {
    s += (m.position() + m.length());

    printf("size = %zu;\n", m.size());
    for (size_t i = 0; i < m.size(); i++) {
      printf("$%zu = \"%s\";\n", i, m[i].str().c_str());
    } // $1 => m[1].str().c_str()
  }
  return 0;
}
