// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <cstdint>

# define FUNC auto
# define cast(t) (t)

typedef char char8_t;

namespace str  { typedef const char8_t* slots_t; } typedef str::slots_t  str_t;
namespace hash { typedef uintptr_t      slots_t; } typedef hash::slots_t hash_t;

constexpr FUNC dk_hash(str_t str) -> hash_t { // Daniel J. Bernstein
  return !*str ? cast(hash_t)5381 : cast(hash_t)(*str) ^ (cast(hash_t)33 * dk_hash(str + 1));
}
