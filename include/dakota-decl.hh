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

# pragma once

# include <type_traits> // add-const<>(), remove-const<>()

# define KLASS_NS namespace
# define TRAIT_NS namespace

# define GENERIC
# define FUNC    auto
# define METHOD  auto

# define ALIAS(...)
# define METHOD_ALIAS(a, r)
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

# define SENTINEL_PTR cast(const keyword_t*)nullptr

# define typealias using

# define cast(t) (t)

// gcc has bug in code generation so the assembler omit the quotes
# if defined __clang__
  # define read_only  gnu::section("__DKT_READ_ONLY, __dkt_read_only")
# elif defined __GNUC__
  # define read_only  gnu::section("\"__DKT_READ_ONLY, __dkt_read_only\"")
# else
  # error "Neither __clang__ nor __GNUC__ is defined."
#endif

# define format_va_printf(n) gnu::format(__printf__, n, 0)
# define format_va_scanf(n)  gnu::format(__scanf__,  n, 0)
# define format_printf(n)    gnu::format(__printf__, n, n + 1)
# define format_scanf(n)     gnu::format(__scanf__,  n, n + 1)
# define sentinel            gnu::sentinel
# define unused              gnu::unused

# define UNBOX_ATTRS  gnu::pure,gnu::hot,gnu::nothrow
# define INLINE_ATTRS gnu::flatten,gnu::always_inline

# if defined _WIN32 || defined _WIN64
  # define so_import ms::dllimport
//# define so_hidden
  # define so_export ms::dllexport
# else
  # define so_import
  # define so_hidden gnu::visibility("hidden")
  # define so_export gnu::visibility("default")
# endif

# define _dkt_typeinfo_ so_export

# if 0
  # define dkt_typeinfo _dkt_typeinfo_
# else
  # define dkt_typeinfo
# endif

typealias int_t =           int;
typealias uint_t = unsigned int;

typealias  char_t =          char; // may be signed or unsigned (same with wchar-t)
typealias schar_t =   signed char;
typealias uchar_t = unsigned char;

typealias  char8_t =  char_t;
typealias schar8_t = schar_t;
typealias uchar8_t = uchar_t;

typealias bool_t = bool;

// integer promotions are
//   float              -> double
//   char               -> int or unsigned int
//   signed char        -> int
//   unsigned char      -> unsigned int
//   short int          -> int
//   unsigned short int -> unsigned int
//   bool               -> unsigned int

typealias va_list_t = va_list; // no corresponding klass/slots defn

typealias float32_t =  float;
typealias float64_t =       double;
typealias float128_t = long double;

// symbols are defined before klasses

# include <dakota-object.hh>

KLASS_NS boole        { typealias slots_t = bool_t;                                } typealias bool_t =         boole::slots_t;
KLASS_NS cmp          { typealias slots_t = int_t;                                 } typealias cmp_t =          cmp::slots_t;
KLASS_NS compare      { typealias slots_t = FUNC (*)(object_t, object_t) -> cmp_t; } typealias compare_t =      compare::slots_t;
KLASS_NS generic_func { typealias slots_t = FUNC (*)(object_t) -> object_t;        } typealias generic_func_t = generic_func::slots_t;
KLASS_NS ptr          { typealias slots_t = void*;                                 } typealias ptr_t =          ptr::slots_t;
KLASS_NS str          { typealias slots_t = const char_t*;                         } typealias str_t =          str::slots_t;
KLASS_NS symbol       { typealias slots_t = str_t;                                 } typealias symbol_t =       symbol::slots_t;
