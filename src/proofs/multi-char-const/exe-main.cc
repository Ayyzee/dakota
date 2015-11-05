# include <errno.h>
# include <stdio.h>
# include <unistd.h>
# include <assert.h>

void
pis(int8_t i)
{
  printf("%li\n", sizeof(i));
  printf(" %.*s\n", (int)sizeof(i), (char*)&i);
  for (uint32_t j = 0; j < sizeof(i); j++)
    printf(" %02x", ((char*)&i)[j]);
  printf("\n");
}

void
pis(int16_t i)
{
  printf("%li\n", sizeof(i));
  printf(" %.*s\n", (int)sizeof(i), (char*)&i);
  for (uint32_t j = 0; j < sizeof(i); j++)
    printf(" %02x", ((char*)&i)[j]);
  printf("\n");
}

void
pis(int32_t i)
{
  printf("%li\n", sizeof(i));
  printf(" %.*s\n", (int)sizeof(i), (char*)&i);
  for (uint32_t j = 0; j < sizeof(i); j++)
    printf(" %02x", ((char*)&i)[j]);
  printf("\n");
}

int main()
{
  int8_t  c1_1 = 'a';
  int16_t c1_2 = 'a';
  int32_t c1_4 = 'a';
  pis(c1_1);
  pis(c1_2);
  pis(c1_4);

# if 1
  int16_t c2_2 = 'ab';
  int32_t c2_4 = 'ab';
  pis(c2_2);
  pis(c2_4);
# endif

  int32_t c4_4 = 'abcd';
  pis(c4_4);

  return 0;
}
