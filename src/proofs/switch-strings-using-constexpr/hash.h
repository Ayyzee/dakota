constexpr unsigned int dkt_hash_recursive(unsigned int hash, const char* str)
{
  return (!*str ? hash : dkt_hash_recursive(((hash << 5) + hash) + *str, str + 1));
}
constexpr unsigned int dk_hash(const char* str)
{
  return (!str ? 0 : dkt_hash_recursive(5381, str));
}

// constexpr unsigned int str2int(const char* str, int h = 0)
// {
//   return !str[h] ? 5381 : (str2int(str, h + 1) * 33) ^ str[h];
// }

