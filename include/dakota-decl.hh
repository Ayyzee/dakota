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
# define MODULE_IMPORT(n1, n2, ...)
# define PROVIDE(t)
# define REQUIRE(t)
# define SLOTS(t, ...)
# define SUPERKLASS(k)
# define KLASS(k)
# define TRAIT(t)
# define TRAITS(t1, ...)

# if defined _WIN32 || defined _WIN64
  # define so_import ms::dllimport
  # define so_export ms::dllexport
# else
  # define so_import
  # define so_export gnu::visibility("default")
# endif

# define dkt_enable_typeinfo so_export

typedef bool boole_t;

typedef          char  char8_t; // may be signed or unsigned (same with wchar-t)
typedef   signed char schar8_t;
typedef unsigned char uchar8_t;


// integer promotions are
//   float -> double
//   char  -> int or unsigned int
//   bool  -> unsigned int

typedef double double_t;
typedef          int    int_t; // no corresponding klass/slots defn
typedef unsigned int   uint_t; // no corresponding klass/slots defn


typedef va_list va_list_t; // no corresponding klass/slots defn

// <cstdfloat>
typedef float       float32_t;
typedef double      float64_t;
typedef long double float128_t;

namespace symbol { typedef char8_t const* slots_t; } typedef symbol::slots_t symbol_t;

static_assert(32/8  == sizeof(float32_t),  "The sizeof float32-t  must equal  32/8 bytes in size");
static_assert(64/8  == sizeof(float64_t),  "The sizeof float64-t  must equal  64/8 bytes in size");
static_assert(128/8 == sizeof(float128_t), "The sizeof float128-t must equal 128/8 bytes in size");

# endif
