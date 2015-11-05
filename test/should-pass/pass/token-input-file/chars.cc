// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <stdio.h>
# include <ctype.h>

int main()
{
  int c = 0;
	for (int i = '!'; i <= '~'; i++)
  {
    if ('_' != i && !isalnum(i))
    {
      c++;
      printf("%c", i);
    }
  }
  printf("\n");
	for (int a = 0; a < c; a++)
  {
    printf("%c", '0' + (a % 10));
  }
  printf("\n");
  return 0;
}
