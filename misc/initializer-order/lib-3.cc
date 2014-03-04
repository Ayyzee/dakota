#include <stdio.h>

void dk_register(int);

__attribute__((constructor)) static void initialize()
{
     dk_register('3');
     return;
}

static char reg_buf[4 + 1] = "";
static int reg_buf_pos = 0;

void dk_register(int c)
{
     reg_buf[reg_buf_pos] = (char)c;
     reg_buf_pos++;
     reg_buf[reg_buf_pos] = (char)0;
     return;
}

char* get_reg_buf()
{
     return reg_buf;
}
