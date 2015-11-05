# include <cstdio>
# include <cstdlib>

# define THREAD_LOCAL __thread
typedef char const* str_t;

static str_t dkt_capture_current_exception(str_t arg)
{
  THREAD_LOCAL static str_t result;
  if (arg) result = arg;
  return result;
}

int main()
{
  printf("%s\n", dkt_capture_current_exception("one"));
  printf("%s\n", dkt_capture_current_exception("two"));
  printf("%s\n", dkt_capture_current_exception("three"));
  printf("%s\n", dkt_capture_current_exception(NULL));
  printf("%s\n", dkt_capture_current_exception("five"));
  
  return 0;
}
