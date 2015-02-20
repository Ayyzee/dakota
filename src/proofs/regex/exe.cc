#include <regex>
#include <string>
#include <cstdlib>
#include <cstdio>

int main()
{
  char const* s = "this subject has a submarine as a subsequence";
  std::cmatch m;
  std::regex e ("\\b(sub)([^ ]*)");   // matches words beginning by "sub"
  size_t mark_count = e.mark_count();
  printf("mark_count = %zu;\n", mark_count);
  char const** dlr = (char const**)malloc(sizeof(char*) * (mark_count + 1));

  while (std::regex_search(s, m, e)) {
    size_t size = m.size();
    size_t i = 0;
    for (auto x:m)
      dlr[i++] = strdup(x.str().c_str()); // leakleak
    for (i = size; i < mark_count + 1; i++)
      dlr[i] = "";
    s += (m.position() + m.length());

    printf("size = %zu;\n", size);
    for (i = 0; i < size; i++) {
      printf("$%zu = \"%s\";\n", i, dlr[i]);
    } // $1 => dlr[1]
  }
  return 0;
}
