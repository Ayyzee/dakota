#include <stdio.h>

void dk_register(int);

__attribute__((constructor)) static void initialize()
{
     dk_register('2');
     return;
}
