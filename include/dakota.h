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

#if !defined __dakota_h__
#define      __dakota_h__

#include <cstddef>
#include <cstdlib>
#include <cstdio>
#include <cstdarg> // va_list
#include <cstdint>

#if defined WIN32
  #include <windows.h>
#endif // WIN32

#if defined DEBUG
  #define DEBUG_STMT(stmt) stmt
#else
  #define DEBUG_STMT(stmt)
#endif

#define DKT_WORKAROUND 1

#if defined WIN32
  #define format_va_printf(fmtarg)
  #define format_va_scanf(fmtarg)
  #define format_printf(fmtarg)
  #define format_scanf(fmtarg)
  #define flatten
  #define pure
  #define sentinel
  #define unused
  #define import   __declspec(dllimport)
  #define export   __declspec(dllexport)
  #define noexport
  #define artificial
  #define leaf
  #define nothrow
  #define hot
  #define designated_init
  #define noreturn
#else
  #define format_va_printf(fmtarg) __attribute__((__format__(__printf__, fmtarg, 0)))
  #define format_va_scanf(fmtarg)  __attribute__((__format__(__scanf__,  fmtarg, 0)))
  #define format_printf(fmtarg)    __attribute__((__format__(__printf__, fmtarg, fmtarg + 1)))
  #define format_scanf(fmtarg)     __attribute__((__format__(__scanf__,  fmtarg, fmtarg + 1)))
  #define flatten  __attribute__((__flatten__))
  #define pure     __attribute__((__pure__))
  #define sentinel __attribute__((__sentinel__))
  #define unused   __attribute__((__unused__))
  #define import
  #define export   __attribute__((__visibility__("default")))
  #define noexport __attribute__((__visibility__("hidden")))
  #define artificial __attribute__((__artificial__))
  #define leaf       __attribute__((__leaf__))
  #define nothrow    __attribute__((__nothrow__))
// don't forget about noexcept
  #define hot        __attribute__((__hot__))
  #define designated_init __attribute__((__designated_init__))
  #if 0
    #define noreturn  __attribute__((__noreturn__))
  #else
    #define noreturn [[noreturn]]
  #endif
#endif

#define unbox_attrs pure hot nothrow

#if !defined HAVE_STRERROR_NAME
  import const char8_t* strerror_name(int_t);
#endif

#if !defined USE
  #define    USE(v) (void)v
#endif

#define cast(t) (t)
#define DK_ARRAY_LENGTH(array) (sizeof((array))/sizeof((array)[0]))

#define dkt_klass(object)   (object)->klass
#define dkt_superklass(kls) klass::unbox(kls)->superklass
#define dkt_name(kls)       klass::unbox(kls)->name

#define dkt_normalize_compare_result(n) ((n) < 0) ? -1 : ((n) > 0) ? 1 : 0
#define dkt_raw_signature(name,args) (cast(dkt_signature_function_t)(cast(const signature_t* (*)args) __raw_signature::name))()
#define dkt_signature(name, args)    (cast(dkt_signature_function_t)(cast(const signature_t* (*)args) __signature::name))()
#define dkt_ka_signature(name, args) (cast(dkt_signature_function_t)(cast(const signature_t* (*)args) __ka_signature::name))()

#define selector(name, args)    *(cast(dkt_selector_function_t) (cast(selector_t*        (*)args) __selector::name))()
#define unless(e) if (0 == (e))
#define until(e)  while (0 == (e))

#define intstr(c1, c2, c3, c4) \
   ((((cast(int32_t)cast(char8_t) c1) << 24) & 0xff000000) | \
    (((cast(int32_t)cast(char8_t) c2) << 16) & 0x00ff0000) | \
    (((cast(int32_t)cast(char8_t) c3) <<  8) & 0x0000ff00) | \
    (((cast(int32_t)cast(char8_t) c4) <<  0) & 0x000000ff))

#if !defined NUL
  #define    NUL cast(char)0
#endif

// boole-t is promoted to int-t when used in va_arg() macro
typedef int_t dkt_va_arg_boole_t;
typedef va_list va_list_t;

#if defined DEBUG
  #define DKT_TRACE(statement) statement
  #define DKT_TRACE_BEFORE(signature, method, ...) dkt_trace_before(signature, method, __VA_ARGS__)
  #define DKT_TRACE_AFTER( signature, method, ...) dkt_trace_after( signature, method, __VA_ARGS__)
#else
  #define DKT_TRACE(statement)
  #define DKT_TRACE_BEFORE(signature, method, ...)
  #define DKT_TRACE_AFTER( signature, method, ...)
#endif

#if defined DEBUG
  #define DKT_VA_TRACE_BEFORE_INIT(kls, args) dkt_va_trace_before_init(kls, args)
  #define DKT_VA_TRACE_AFTER_INIT( kls, args) dkt_va_trace_after_init(kls, args)
#else
  #define DKT_VA_TRACE_BEFORE_INIT(kls, args)
  #define DKT_VA_TRACE_AFTER_INIT( kls, args)
#endif

#if defined DKT_USE_MAKE_MACRO
  #if DEBUG
    #define make(kls, ...) dk::init(dk::alloc(kls, __FILE__, __LINE__), __VA_ARGS__)
  #else
    #define make(kls, ...) dk::init(dk::alloc(kls), __VA_ARGS__)
  #endif
#endif

#define PRIxPTR_WIDTH cast(int_t)(2 * sizeof(uintptr_t))

extern import object_t null;
extern import object_t std_input;
extern import object_t std_output;
extern import object_t std_error;

typedef int_t  (*compare_t)(object_t, object_t); // comparitor
typedef uintmax_t (*hash_t)(object_t);
typedef const signature_t* (*dkt_signature_function_t)();
typedef selector_t* (*dkt_selector_function_t)();

constexpr uintmax_t dkt_hash_recursive(uintmax_t hash, const char8_t* str)
{
  return (!*str ? hash : dkt_hash_recursive(((hash << 5) + hash) ^ cast(uchar8_t)*str, str + 1));
}
constexpr uintmax_t dk_hash(const char8_t* str)
{ // Daniel J. Bernstein
  return (!str ? 0 : dkt_hash_recursive(5381, str));
}

// constexpr uintmax_t dk_hash(const char8_t* str, uintmax_t h = 0)
// { // Daniel J. Bernstein
//   return !str[h] ? 5381 : ( dk_hash(str, h + 1) * 33 ) ^ cast(uchar8_t)(str[h]);
// }

import int_t  safe_strcmp(const char8_t*, const char8_t*);
import size_t safe_strlen(const char8_t*);

import symbol_t dk_intern(const char8_t*);
import object_t dk_klass_for_name(symbol_t);

import void dk_register_info(named_info_node_t*);
import void dk_deregister_info(named_info_node_t*);

sentinel import named_info_node_t* dk_make_named_info_slots(symbol_t name, ...);
sentinel import object_t           dk_make_named_info(symbol_t name, ...);

noreturn import void dkt_throw(object_t exception);
noreturn import void dkt_throw(const char8_t* exception_str);

// import object_t dk_va_add_all(object_t self, va_list_t);
// sentinel import object_t dk_add_all(object_t self, ...);

import object_t*       dkt_current_exception();
import const char8_t** dkt_current_exception_str();
import object_t dk_make_simple_klass(symbol_t name, symbol_t superklass_name, symbol_t klass_name);

noreturn import void dkt_null_method(object_t object, ...);

#if defined DEBUG
  #define DKT_NULL_METHOD nullptr
#else
  #define DKT_NULL_METHOD dkt_null_method
#endif

#if defined DEBUG
  import named_info_node_t* dk_va_make_named_info_slots(symbol_t name, va_list_t args);
  import object_t           dk_va_make_named_info(symbol_t name, va_list_t args);

  import int_t dkt_va_trace_before(const signature_t* signature, method_t m, object_t object, va_list_t args);
  import int_t dkt_va_trace_before(const signature_t* signature, method_t m, super_t context, va_list_t args);
  import int_t dkt_va_trace_after(const signature_t* signature, method_t m, object_t object, va_list_t args);
  import int_t dkt_va_trace_after(const signature_t* signature, method_t m, super_t context, va_list_t args);

  import int_t dkt_trace_before(const signature_t* signature, method_t method, super_t context, ...);
  import int_t dkt_trace_before(const signature_t* signature, method_t method, object_t object, ...);
  import int_t dkt_trace_after( const signature_t* signature, method_t method, super_t context, ...);
  import int_t dkt_trace_after( const signature_t* signature, method_t method, object_t object, ...);

  import int_t dkt_va_trace_before_init(object_t kls, va_list_t);
  import int_t dkt_va_trace_after_init( object_t kls, va_list_t);

  import char8_t* dkt_get_klass_chain(object_t klass, char8_t* buf, uint32_t buf_len);

  import void dkt_dump_methods(object_t);
  import void dkt_dump_methods(klass::slots_t*);

  import void dkt_unbox_check(object_t object, object_t kls);
#endif

#endif // __dakota_h__
