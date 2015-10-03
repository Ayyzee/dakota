// g++ --ansi --pedantic --output exe exe-main.cc

void foo(int[])
{
  return;
}

int main()
{
  // this fails with
  // error: ISO C++ forbids compound-literals
  foo((int[]){ 1, 2 });
  return 0;
}
