#include <stdio.h>
typedef char char8_t;
typedef unsigned int uint_t;

namespace __tuple
{
  struct const_char8_t_2a_3b_uint_t_3b_t { const char8_t* _0; uint_t _1; };
}

__tuple::const_char8_t_2a_3b_uint_t_3b_t
bar1()
{
  __tuple::const_char8_t_2a_3b_uint_t_3b_t result = { "war & peace", 996 };
  return result;
}

__tuple::const_char8_t_2a_3b_uint_t_3b_t
bar2()
{
  __tuple::const_char8_t_2a_3b_uint_t_3b_t result;
  //
  result._0 = "war & peace";
  result._1 = 996;
  return result;
}

void
foo1()
{
  __tuple::const_char8_t_2a_3b_uint_t_3b_t book = bar1();
  printf("\"%s\", %i\n",
         book._0,
         book._1);
}

void
foo2()
{
  struct { const char8_t* title; uint_t pages; } book;
  //
  __tuple::const_char8_t_2a_3b_uint_t_3b_t __tuple_book = bar2(); book.title = __tuple_book._0; book.pages = __tuple_book._1;//
  printf("\"%s\", %i\n",
         book.title,
         book.pages);
}

int_t
main()
{
  foo1();
  foo2();
  return 0;
}
