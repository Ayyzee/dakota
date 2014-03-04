#include <assert.h>
#include <stdio.h>
#include <string.h>

void dk_register(int);

__attribute__((constructor)) static void initialize()
{
     dk_register('1');
     return;
}

char* get_reg_buf();

int main()
{
     char* reg_buf = get_reg_buf();
     printf("%s\n", reg_buf);
     assert(!strcmp("3221", reg_buf));
     return 0;
}
