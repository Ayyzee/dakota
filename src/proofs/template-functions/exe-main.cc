# include <cstdio>
# include <cstdlib>

# define THREAD_LOCAL __thread // bummer that clang does not support thread_local on darwi

template <class type> type add(type a, type b)
{
  return a + b;
}

template <class type> type dkt_capture_current_exception(type arg)
{
  static THREAD_LOCAL type result;
  if (arg) result = arg;
  return result;
}

int main()
{
  
  int x1 = add(1, 2);
  int x2 = add<int>(1, 2);

  dkt_capture_current_exception((int)0);
  dkt_capture_current_exception("bummer");
  dkt_capture_current_exception(nullptr);

  return 0;
}
