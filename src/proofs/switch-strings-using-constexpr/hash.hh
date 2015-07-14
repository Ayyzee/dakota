#include <cstdint>

typedef char char8_t;
typedef unsigned char uchar8_t;
typedef char8_t const* str_t;

#define cast(t) (t)

#if 0
constexpr uint32_t dkt_hash_recursive(uint32_t hash, const char8_t* str) {
  return (!*str ? hash : dkt_hash_recursive(((hash << 5) + hash) + cast(uint8_t) *str, str + 1));
}
constexpr uint32_t dk_hash(const char8_t* str) {
  return (!str ? 0 : dkt_hash_recursive(5381, str));
}
#endif

// constexpr uint64_t dkt_hash_recursive(uint64_t hash, const char8_t* str) {
//   return (!*str ? hash : dkt_hash_recursive(((hash << cast(uint64_t)5) + hash) + cast(uint8_t) *str, str + 1));
// }
// constexpr uint64_t dk_hash64(const char8_t* str) {
//   return (!str ? 0 : dkt_hash_recursive(cast(uint64_t)5381, str));
// }
// constexpr uint64_t dk_hash64(const char8_t* str) {
//   return (!str ? 0 : dkt_hash_recursive(cast(uint64_t)5381, str));
// }

#if 1
constexpr uint32_t dk_hash(str_t str, uint32_t i = 0) { // Daniel J. Bernstein
  return !str[i] ? cast(uint32_t)5381 : ( dk_hash(str, i + 1) * cast(uint32_t)33 ) ^ cast(uchar8_t)(str[i]);
}
#else
constexpr uint64_t dk_hash(str_t str, uint64_t i = 0) { // Daniel J. Bernstein
  return !str[i] ? cast(uint64_t)5381 : ( dk_hash(str, i + 1) * cast(uint64_t)33 ) ^ cast(uint8_t)(str[i]);
}
#endif
// constexpr uint32_t str2int(const char8_t* str, int h = 0)
// {
//   return !str[h] ? 5381 : (str2int(str, h + 1) * 33) ^ str[h];
// }

#if 0
unsigned int DJBHash(const std::string& str)
{
  unsigned int hash = 5381;

  for(std::size_t i = 0; i < str.length(); i++)
    {
      hash = ((hash << 5) + hash) + str[i];
    }

  return (hash & 0x7FFFFFFF);
}

unsigned long
hash(unsigned char *str) {
  unsigned long hash = 5381;
  int c;

  while (c = *str++)
#if 0
  hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
#else
  hash = ((hash << 5) + hash) ^ c;
#endif
  return hash;
}
#endif
