#include <stdio.h>

#include "pg.h"

int main()
{
     int* mol = (int*)pg_malloc(sizeof(int));

     *mol = 0;

     pg_guard_read(mol);

     int i = *mol; // causes fault
     (void)i;

     pg_guard_write(mol);

     *mol = 0; // causes fault

     return 0;
}
