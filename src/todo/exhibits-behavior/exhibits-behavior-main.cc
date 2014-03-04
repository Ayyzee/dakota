#include <stdio.h>
#include <gmp.h>

// mpz_t;
// void    mpz_init(mpz_t);
// void    mpz_setbit(mpz_t, uint32_t);
// void    mpz_clrbit(mpz_t, uint32_t);
// void    mpz_and(mpz_t, mpz_t, mpz_t);
// int32_t mpz_cmp(mpz_t, mpz_t); // -1 or 0 or +1
// void    mpz_clear(mpz_t);

int main()
{
     mpz_t behavior1;
     mpz_init(behavior1);

     // sample behavior declaration
     mpz_setbit(behavior1, 33);
     mpz_setbit(behavior1, 34);
     
     mpz_t behavior2;
     mpz_init(behavior2);

     // sample klass or trait definition (implementation)
     mpz_setbit(behavior2, 31);
     mpz_setbit(behavior2, 32);
     mpz_setbit(behavior2, 33);
     mpz_setbit(behavior2, 34);
     mpz_setbit(behavior2, 35);
     mpz_setbit(behavior2, 36);

     mpz_t result;
     mpz_init(result);
     mpz_and(result, behavior1, behavior2);
     
     gmp_printf ("behavior-1: %#Zx\n", behavior1);
     gmp_printf ("behavior-2: %#Zx\n", behavior2);
     gmp_printf ("result: %#Zx (behavior-1 & behavior-2)\n", result);

     if (0 == mpz_cmp(result,  behavior1))
          printf("behavior-2 defines (exhibits) behavior declared by behavior-1\n");

     mpz_clear(behavior1);
     mpz_clear(behavior2);
     mpz_clear(result);

     return 0;
}
