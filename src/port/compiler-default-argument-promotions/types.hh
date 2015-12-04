// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <limits>
# include <cstdint>

typedef va_list va_list_t;

typedef bool boole_t;

typedef          char  char_t;
typedef   signed char schar_t;
typedef unsigned char uchar_t;

typedef          int  int_t;
typedef unsigned int uint_t;

namespace std { typedef float       float32_t;  }
namespace std { typedef double      float64_t;  }
namespace std { typedef long double float128_t; }

static_assert(32/8  == sizeof(std::float32_t),  "The sizeof std::float32-t  must equal  32/8 bytes in size");
static_assert(64/8  == sizeof(std::float64_t),  "The sizeof std::float64-t  must equal  64/8 bytes in size");
static_assert(128/8 == sizeof(std::float128_t), "The sizeof std::float128-t must equal 128/8 bytes in size");

namespace boole { typedef boole_t slots_t; } typedef boole::slots_t boole_t;

namespace char8 { typedef char_t slots_t; } typedef char8::slots_t char8_t;
namespace uchar8 { typedef uchar_t slots_t; } typedef uchar8::slots_t uchar8_t;
namespace schar8 { typedef schar_t slots_t; } typedef schar8::slots_t schar8_t;

namespace char16 { typedef char16_t slots_t; } //typedef char16::slots_t char16_t;
namespace char32 { typedef char32_t slots_t; } //typedef char32::slots_t char32_t;

namespace wchar { typedef wchar_t slots_t; } //typedef wchar::slots_t wchar_t;

namespace int8 { typedef int8_t slots_t; } typedef int8::slots_t int8_t;
namespace int16 { typedef int16_t slots_t; } typedef int16::slots_t int16_t;
namespace int32 { typedef int32_t slots_t; } typedef int32::slots_t int32_t;
namespace int64 { typedef int64_t slots_t; } typedef int64::slots_t int64_t;

namespace int_fast8 { typedef int_fast8_t slots_t; } typedef int_fast8::slots_t int_fast8_t;
namespace int_fast16 { typedef int_fast16_t slots_t; } typedef int_fast16::slots_t int_fast16_t;
namespace int_fast32 { typedef int_fast32_t slots_t; } typedef int_fast32::slots_t int_fast32_t;
namespace int_fast64 { typedef int_fast64_t slots_t; } typedef int_fast64::slots_t int_fast64_t;

namespace int_least8 { typedef int_least8_t slots_t; } typedef int_least8::slots_t int_least8_t;
namespace int_least16 { typedef int_least16_t slots_t; } typedef int_least16::slots_t int_least16_t;
namespace int_least32 { typedef int_least32_t slots_t; } typedef int_least32::slots_t int_least32_t;
namespace int_least64 { typedef int_least64_t slots_t; } typedef int_least64::slots_t int_least64_t;

namespace uint8 { typedef uint8_t slots_t; } typedef uint8::slots_t uint8_t;
namespace uint16 { typedef uint16_t slots_t; } typedef uint16::slots_t uint16_t;
namespace uint32 { typedef uint32_t slots_t; } typedef uint32::slots_t uint32_t;
namespace uint64 { typedef uint64_t slots_t; } typedef uint64::slots_t uint64_t;

namespace uint_fast8 { typedef uint_fast8_t slots_t; } typedef uint_fast8::slots_t uint_fast8_t;
namespace uint_fast16 { typedef uint_fast16_t slots_t; } typedef uint_fast16::slots_t uint_fast16_t;
namespace uint_fast32 { typedef uint_fast32_t slots_t; } typedef uint_fast32::slots_t uint_fast32_t;
namespace uint_fast64 { typedef uint_fast64_t slots_t; } typedef uint_fast64::slots_t uint_fast64_t;

namespace uint_least8 { typedef uint_least8_t slots_t; } typedef uint_least8::slots_t uint_least8_t;
namespace uint_least16 { typedef uint_least16_t slots_t; } typedef uint_least16::slots_t uint_least16_t;
namespace uint_least32 { typedef uint_least32_t slots_t; } typedef uint_least32::slots_t uint_least32_t;
namespace uint_least64 { typedef uint_least64_t slots_t; } typedef uint_least64::slots_t uint_least64_t;

namespace float32 { typedef std::float32_t slots_t; } typedef float32::slots_t float32_t;
namespace float64 { typedef std::float64_t slots_t; } typedef float64::slots_t float64_t;
