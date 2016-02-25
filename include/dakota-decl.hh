// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// Copyright (C) 2007, 2008, 2009 Robert Nielsen <robert@dakota.org>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

# if !defined dkt_dakota_decl_hh
# define      dkt_dakota_decl_hh

# define KLASS_NS namespace
# define TRAIT_NS namespace

# define GENERIC auto
# define METHOD  auto
# define FUNC    auto
# define SELECTOR_FUNC  FUNC
# define SIGNATURE_FUNC FUNC

# define VA_SELECTOR_FUNC  FUNC
# define VA_SIGNATURE_FUNC FUNC
# define VA_GENERIC        GENERIC
# define VA_METHOD         METHOD
# define KW_ARGS_METHOD    METHOD

# define KW_ARGS_METHOD_SIGNATURE_FUNC FUNC
# define SLOTS_METHOD_SIGNATURE_FUNC   FUNC

# define ALIAS(m)
# define METHOD_ALIAS(a, r)
# define INCLUDE(f)
# define INTERPOSE(k)
# define MODULE(n)
# define MODULE_EXPORT(n, ...)
# define MODULE_IMPORT(n, ...)
# define PROVIDE(t)
# define REQUIRE(t)
# define SLOTS(t, ...)
# define SUPERKLASS(k)
# define KLASS(k)
# define TRAIT(t)
# define TRAITS(t1, ...)

# define SENTINAL_PTR nullptr

# if defined _WIN32 || defined _WIN64
  # define import ms::dllimport
  # define export ms::dllexport
# else
  # define import
  # define export gnu::visibility("default")
# endif

# if 0
# define dkt_enable_typeinfo [[export]]
# else
# define dkt_enable_typeinfo
# endif

using boole_t = bool;

using  char8_t =          char; // may be signed or unsigned (same with wchar-t)
using schar8_t =   signed char;
using uchar8_t = unsigned char;

// integer promotions are
//   float -> double
//   char  -> int or unsigned int
//   bool  -> unsigned int

using double_t = double;
using  int_t =          int; // no corresponding klass/slots defn
using uint_t = unsigned int; // no corresponding klass/slots defn

using va_list_t = va_list; // no corresponding klass/slots defn

// <cstdfloat>
namespace std { using float32_t =  float; }
namespace std { using float64_t =       double; }
namespace std { using float128_t = long double; }

namespace symbol { using slots_t = const char8_t*; } using symbol_t = symbol::slots_t;

static_assert(32/8  == sizeof(std::float32_t),  "The sizeof std::float32-t  must equal  32/8 bytes in size");
static_assert(64/8  == sizeof(std::float64_t),  "The sizeof std::float64-t  must equal  64/8 bytes in size");
static_assert(128/8 == sizeof(std::float128_t), "The sizeof std::float128-t must equal 128/8 bytes in size");

# endif
