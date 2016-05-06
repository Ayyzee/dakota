// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <limits>
# include <cstdint>

using va_list_t = va_list;

using boole_t = bool;

using  char_t =          char;
using schar_t =   signed char;
using uchar_t = unsigned char;

using  int_t =          int;
using uint_t = unsigned int;

namespace std { using float32_t =  float;  }
namespace std { using float64_t =       double; }
namespace std { using float128_t = long double; }

static_assert(32/8  == sizeof(std::float32_t),  "The sizeof std::float32-t  must equal  32/8 bytes in size");
static_assert(64/8  == sizeof(std::float64_t),  "The sizeof std::float64-t  must equal  64/8 bytes in size");
static_assert(128/8 == sizeof(std::float128_t), "The sizeof std::float128-t must equal 128/8 bytes in size");

namespace boole { using slots_t = boole_t; } using boole_t = boole::slots_t;

namespace char8 { using slots_t = char_t; } using char8_t = char8::slots_t;
namespace uchar8 { using slots_t = uchar_t; } using uchar8_t = uchar8::slots_t;
namespace schar8 { using slots_t = schar_t; } using schar8_t = schar8::slots_t;

namespace char16 { using slots_t = char16_t; } //using char16_t = char16::slots_t;
namespace char32 { using slots_t = char32_t; } //using char32_t = char32::slots_t;

namespace wchar { using slots_t = wchar_t; } //using wchar_t = wchar::slots_t;

namespace int8 { using slots_t = int8_t; } using int8_t = int8::slots_t;
namespace int16 { using slots_t = int16_t; } using int16_t = int16::slots_t;
namespace int32 { using slots_t = int32_t; } using int32_t = int32::slots_t;
namespace int64 { using slots_t = int64_t; } using int64_t = int64::slots_t;

namespace int_fast8 { using slots_t = int_fast8_t; } using int_fast8_t = int_fast8::slots_t;
namespace int_fast16 { using slots_t = int_fast16_t; } using int_fast16_t = int_fast16::slots_t;
namespace int_fast32 { using slots_t = int_fast32_t; } using int_fast32_t = int_fast32::slots_t;
namespace int_fast64 { using slots_t = int_fast64_t; } using int_fast64_t = int_fast64::slots_t;

namespace int_least8 { using slots_t = int_least8_t; } using int_least8_t = int_least8::slots_t;
namespace int_least16 { using slots_t = int_least16_t; } using int_least16_t = int_least16::slots_t;
namespace int_least32 { using slots_t = int_least32_t; } using int_least32_t = int_least32::slots_t;
namespace int_least64 { using slots_t = int_least64_t; } using int_least64_t = int_least64::slots_t;

namespace uint8 { using slots_t = uint8_t; } using uint8_t = uint8::slots_t;
namespace uint16 { using slots_t = uint16_t; } using uint16_t = uint16::slots_t;
namespace uint32 { using slots_t = uint32_t; } using uint32_t = uint32::slots_t;
namespace uint64 { using slots_t = uint64_t; } using uint64_t = uint64::slots_t;

namespace uint_fast8 { using slots_t = uint_fast8_t; } using uint_fast8_t = uint_fast8::slots_t;
namespace uint_fast16 { using slots_t = uint_fast16_t; } using uint_fast16_t = uint_fast16::slots_t;
namespace uint_fast32 { using slots_t = uint_fast32_t; } using uint_fast32_t = uint_fast32::slots_t;
namespace uint_fast64 { using slots_t = uint_fast64_t; } using uint_fast64_t = uint_fast64::slots_t;

namespace uint_least8 { using slots_t = uint_least8_t; } using uint_least8_t = uint_least8::slots_t;
namespace uint_least16 { using slots_t = uint_least16_t; } using uint_least16_t = uint_least16::slots_t;
namespace uint_least32 { using slots_t = uint_least32_t; } using uint_least32_t = uint_least32::slots_t;
namespace uint_least64 { using slots_t = uint_least64_t; } using uint_least64_t = uint_least64::slots_t;

namespace float32 { using slots_t = std::float32_t; } using float32_t = float32::slots_t;
namespace float64 { using slots_t = std::float64_t; } using float64_t = float64::slots_t;
