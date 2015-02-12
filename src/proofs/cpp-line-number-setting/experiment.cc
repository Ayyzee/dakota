#line 1 "./experiment.dk" 
#include <stdio.h>
int main() {
  //#line __LINE__ // essentialy subtracts one from the __LINE__ variable
  printf("%s:%i: here i am\n", __FILE__, __LINE__);
  return 0;
}
