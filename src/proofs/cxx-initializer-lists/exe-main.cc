# include <initializer_list>

struct cstr_t {
  int          len;
  const char * str;
};

int main()
{
  std::initializer_list<std::initializer_list<cstr_t>> cstrs
    = { { 0, "" }, { 3, "abc" }, { 5, "abcde" } };

  const char * str = cstrs[0].str;
  
  return 0;
}
