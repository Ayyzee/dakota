#include <stdint.h>

int main()
{
  uintmax_t hash;
  uint32_t num_buckets;
  uint32_t result = hash % num_buckets;
  (void)result;
  return 0;
}
