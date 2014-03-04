struct int_char_ptr_t { int _0; char* _1; };

void foo()
{
#if 0
  ${ int; char*; } t = ${ 42, "meaning of life" };
  int   i = t.0;
  char* s = t.1;
#endif
  int_char_ptr_t t = { 42, "meaning of life" };
  int   i = t._0;
  char* s = t._1;

  (void)i;
  (void)s;
}
