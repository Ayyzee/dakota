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

#if !defined dkt_dakota_hh
#define      dkt_dakota_hh

#include <cstddef>
#include <cstdlib>
#include <cstdio>
#include <cstdarg> // va_list
#include <cstdint>
#include <cstring> // memcpy()
#include <new> // std::bad_alloc

#if defined WIN32
  #include <windows.h>
#endif // WIN32

#define DKT_MEM_MGMT_MALLOC 0
#define DKT_MEM_MGMT_NEW    1
#define DKT_MEM_MGMT        DKT_MEM_MGMT_MALLOC

namespace dkt {
  inline void dealloc(void* ptr) {
#if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
    operator delete(ptr);
#elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
    free(ptr);
#else
    #error DK_MEM_MGMT
#endif
  }
  inline void* alloc(std::size_t size) {
    void* buf;
#if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
    buf = operator new(size);
#elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
    buf = malloc(size);

    if (NULL == buf)
      throw std::bad_alloc();
#else
    #error DK_MEM_MGMT
#endif
    return buf;
  }
  inline void* alloc(std::size_t size, void* ptr) {
    void* buf;
#if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
    buf = dkt::alloc(size);
    memcpy(buf, ptr, size);
    dkt::dealloc(ptr);
#elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
    buf = realloc(ptr, size);

    if (NULL == buf)
      throw std::bad_alloc();
#else
    #error DK_MEM_MGMT
#endif
    return buf;
  }
}
#if defined DEBUG
  #define DEBUG_STMT(stmt) stmt
#else
  #define DEBUG_STMT(stmt)
#endif

#if defined WIN32
  #define DKT_RODATA_SECTION
  #define format_va_printf(fmtarg)
  #define format_va_scanf(fmtarg)
  #define format_printf(fmtarg)
  #define format_scanf(fmtarg)
  #define flatten
  #define pure
  #define sentinel
  #define unused
  #define artificial
  #define leaf
  #define nothrow
  #define hot
  #define designated_init
  #define noreturn
#else
  #define DKT_RODATA_SECTION __attribute__((__section__("__DKT_RODATA, __dkt_rodata")))
  #define format_va_printf(fmtarg) __attribute__((__format__(__printf__, fmtarg, 0)))
  #define format_va_scanf(fmtarg)  __attribute__((__format__(__scanf__,  fmtarg, 0)))
  #define format_printf(fmtarg)    __attribute__((__format__(__printf__, fmtarg, fmtarg + 1)))
  #define format_scanf(fmtarg)     __attribute__((__format__(__scanf__,  fmtarg, fmtarg + 1)))
  #define flatten  __attribute__((__flatten__))
  #define pure     __attribute__((__pure__))
  #define sentinel __attribute__((__sentinel__))
  #define unused   __attribute__((__unused__))
  #define artificial __attribute__((__artificial__))
  #define leaf       __attribute__((__leaf__))
  #define nothrow    __attribute__((__nothrow__))
// don't forget about c++s' noexcept
  #define hot        __attribute__((__hot__))
  #define designated_init __attribute__((__designated_init__))
  // #if 0
  //   #define noreturn  __attribute__((__noreturn__))
  // #else
  //   #define noreturn [[noreturn]]
  // #endif
#endif

#define THREAD_LOCAL __thread // bummer that clang does not support thread_local on darwin

#define unbox_attrs pure hot nothrow

#if defined DEBUG
  #define DEBUG_SO_EXPORT SO_EXPORT
  #define DEBUG_IMPORT    SO_IMPORT
#else
  #define DEBUG_SO_EXPORT
  #define DEBUG_IMPORT
#endif

#define NULLPTR nullptr

#if !defined HAVE_STRERROR_NAME
  SO_IMPORT str_t strerror_name(int_t);
#endif

#define cast(t) (t)
#define DK_COUNTOF(array) (sizeof((array))/sizeof((array)[0]))

template <typename T, size_t N>
constexpr size_t dk_countof(T(&)[N]) {
  return N;
}
#if !defined USE
  #define    USE(v) cast(void)v
#endif

#define klass_of(object)   (object)->klass
#define superklass_of(kls) klass::unbox(kls)->superklass
#define name_of(kls)       klass::unbox(kls)->name

inline int_t dkt_normalize_compare_result(intmax_t n) { return (n < 0) ? -1 : (n > 0) ? 1 : 0; }
// file scope
#define selector(name, args)             *(cast(dkt_selector_function_t) (cast(selector_t*        (*)args) __selector::name))()
#define dkt_signature(name, args)         (cast(dkt_signature_function_t)(cast(signature_t const* (*)args) __signature::name))()

// klass/trait scope
#define dkt_slots_signature(name,args)    (cast(dkt_signature_function_t)(cast(signature_t const* (*)args) __slots_signature::name))()
#define dkt_kw_args_signature(name, args) (cast(dkt_signature_function_t)(cast(signature_t const* (*)args) __kw_args_signature::name))()

#define unless(e) if (0 == (e))
#define until(e)  while (0 == (e))

#define intstr(c1, c2, c3, c4) \
   ((((cast(int32_t)cast(char8_t) c1) << 24) & 0xff000000) | \
    (((cast(int32_t)cast(char8_t) c2) << 16) & 0x00ff0000) | \
    (((cast(int32_t)cast(char8_t) c3) <<  8) & 0x0000ff00) | \
    (((cast(int32_t)cast(char8_t) c4) <<  0) & 0x000000ff))

#if !defined NUL
  #define    NUL cast(char_t)0
#endif

// boole-t is promoted to int-t when used in va_arg() macro
typedef int_t dkt_va_arg_boole_t;
typedef va_list va_list_t;


#if defined DK_ENABLE_TRACE_MACROS
  #define DKT_VA_TRACE_BEFORE(signature, method, object, args)               dkt_va_trace_before(signature, method, object, args)
  #define DKT_VA_TRACE_AFTER( signature, method, object, /* result, */ args) dkt_va_trace_after( signature, method, object, args)
  #define DKT_TRACE_BEFORE(signature, method, object, ...)                   dkt_trace_before(   signature, method, object, __VA_ARGS__)
  #define DKT_TRACE_AFTER( signature, method, object, /* result, */ ...)     dkt_trace_after(    signature, method, object, __VA_ARGS__)
  #define DKT_TRACE(statement) statement
#else
  #define DKT_VA_TRACE_BEFORE(signature, method, object, args)
  #define DKT_VA_TRACE_AFTER( signature, method, object, /* result, */ args)
  #define DKT_TRACE_BEFORE(signature, method, object, ...)
  #define DKT_TRACE_AFTER( signature, method, object, /* result, */ ...)
  #define DKT_TRACE(statement)
#endif

#if defined DKT_USE_MAKE_MACRO
  #if DEBUG
    #define make(kls, ...) dk::init(dk::alloc(kls, __FILE__, __LINE__), __VA_ARGS__)
  #else
    #define make(kls, ...) dk::init(dk::alloc(kls), __VA_ARGS__)
  #endif
#endif

#define PRIxPTR_WIDTH cast(int_t)(2 * sizeof(uintptr_t))

extern SO_IMPORT object_t null;
extern SO_IMPORT object_t std_input;
extern SO_IMPORT object_t std_output;
extern SO_IMPORT object_t std_error;

typedef int_t  (*compare_t)(object_t, object_t); // comparitor
typedef uintmax_t (*hash_t)(object_t);
typedef signature_t const* (*dkt_signature_function_t)();
typedef selector_t* (*dkt_selector_function_t)();

constexpr uintptr_t dk_hash(str_t str, uintptr_t i = 0) { // Daniel J. Bernstein
  return !str[i] ? cast(uintptr_t)5381 : ( dk_hash(str, i + 1) * cast(uintptr_t)33 ) ^ cast(uchar8_t)(str[i]);
}
constexpr uintptr_t dkt_hash_switch(str_t str) { return dk_hash(str); }

constexpr  intptr_t dkt_hash_switch( intptr_t val) { return val; }
constexpr uintptr_t dkt_hash_switch(uintptr_t val) { return val; }

constexpr  int_t dkt_hash_switch( int_t val) { return val; }
constexpr uint_t dkt_hash_switch(uint_t val) { return val; }

SO_IMPORT int_t  safe_strcmp(str_t, str_t);
SO_IMPORT size_t safe_strlen(str_t);

SO_IMPORT symbol_t dk_intern(str_t);
SO_IMPORT object_t dk_klass_for_name(symbol_t);

SO_IMPORT void dkt_register_info(named_info_t*);
SO_IMPORT void dkt_deregister_info(named_info_t*);

// SO_IMPORT          object_t dk_va_add_all(object_t self, va_list_t);
// SO_IMPORT sentinel object_t dk_add_all(object_t self, ...);

SO_IMPORT object_t dk_export_klass(named_info_t* klass_info);
SO_IMPORT void dk_init_runtime();
SO_IMPORT object_t dk_make_simple_klass(symbol_t name, symbol_t superklass_name, symbol_t klass_name);

SO_IMPORT object_t dkt_capture_current_exception(object_t arg);
SO_IMPORT str_t    dkt_capture_current_exception(str_t arg);

SO_IMPORT named_info_t* dk_va_make_named_info_slots(symbol_t name, va_list_t args);
SO_IMPORT object_t      dk_va_make_named_info(      symbol_t name, va_list_t args);

SO_IMPORT sentinel named_info_t* dk_make_named_info_slots(symbol_t name, ...);
SO_IMPORT sentinel object_t      dk_make_named_info(      symbol_t name, ...);

DEBUG_IMPORT named_info_t* dkt_dump_named_info(named_info_t* info);

//#define DKT_NULL_METHOD nullptr
#define DKT_NULL_METHOD cast(method_t)dkt_null_method

SO_IMPORT [[noreturn]] void dkt_null_method(object_t object, ...);

DEBUG_IMPORT int_t dkt_va_trace_before(signature_t const* signature, method_t method, object_t object,  va_list_t args);
DEBUG_IMPORT int_t dkt_va_trace_before(signature_t const* signature, method_t method, super_t  context, va_list_t args);
DEBUG_IMPORT int_t dkt_va_trace_after( signature_t const* signature, method_t method, object_t object,  va_list_t args);
DEBUG_IMPORT int_t dkt_va_trace_after( signature_t const* signature, method_t method, super_t  context, va_list_t args);

DEBUG_IMPORT int_t dkt_trace_before(signature_t const* signature, method_t method, super_t  context, ...);
DEBUG_IMPORT int_t dkt_trace_before(signature_t const* signature, method_t method, object_t object,  ...);
DEBUG_IMPORT int_t dkt_trace_after( signature_t const* signature, method_t method, super_t  context, ...);
DEBUG_IMPORT int_t dkt_trace_after( signature_t const* signature, method_t method, object_t object,  ...);

DEBUG_IMPORT char8_t* dkt_get_klass_chain(object_t klass, char8_t* buf, uint32_t buf_len);

DEBUG_IMPORT void dkt_dump_methods(object_t);
DEBUG_IMPORT void dkt_dump_methods(klass::slots_t*);

DEBUG_IMPORT void dkt_unbox_check(object_t object, object_t kls);

#endif // dkt_dakota_hh
