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

# include <cstddef>
# include <cstdlib>
# include <cstdio>
# include <cstdarg> // va-list
# include <cstdint>
# include <cstring> // memcpy()
# include <new> // std::bad-alloc

# include <syslog.h>
# include <cxxabi.h>

# include <dakota-finally.hh>

# define ssizeof(t) (cast(ssize_t)sizeof(t))

# define DKT_MEM_MGMT_MALLOC 0
# define DKT_MEM_MGMT_NEW    1
# define DKT_MEM_MGMT        DKT_MEM_MGMT_MALLOC

# if defined __GNUG__
namespace dkt { inline FUNC demangle(str_t mangled_name) -> str_t {
  int_t status = -1;
  str_t name = abi::__cxa_demangle(mangled_name, 0, 0, &status); // must be free()d
  if (0 == status)
    return name;
  else
    return nullptr;
}}
# else // does nothing if not gcc/clang (g++/clang++)
namespace dkt { inline FUNC demangle(str_t mangled_name) -> str_t {
  return name;
}}
# endif

namespace dkt { inline FUNC dealloc(void* ptr) -> void {
# if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
  operator delete(ptr);
# elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
  free(ptr);
# else
  # error DK_MEM_MGMT
# endif
}}
namespace dkt { inline FUNC alloc(ssize_t size) -> void* {
  void* buf;
# if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
  buf = operator new(size);
# elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
  buf = malloc(cast(size_t)size);

  if (nullptr == buf)
    throw std::bad_alloc();
# else
  # error DK_MEM_MGMT
# endif
  return buf;
}}
namespace dkt { inline FUNC alloc(ssize_t size, void* ptr) -> void* {
  void* buf;
# if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
  buf = dkt::alloc(size);
  memcpy(buf, ptr, size);
  dkt::dealloc(ptr);
# elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
  buf = realloc(ptr, cast(size_t)size);

  if (nullptr == buf)
    throw std::bad_alloc();
# else
  # error DK_MEM_MGMT
# endif
  return buf;
}}
# if defined DEBUG
  # include <typeinfo>
  # define DKT_UNBOX_CHECK_ENABLED 1
  # define DEBUG_STMT(stmt) stmt
  # define INTERNED_DEMANGLED_TYPEID_NAME(t) dk_intern_free(dkt::demangle(typeid(t).name()))
# else
  # define DEBUG_STMT(stmt)
  # define INTERNED_DEMANGLED_TYPEID_NAME(t) nullptr
# endif

# define THREAD_LOCAL __thread // bummer that clang does not support thread-local on darwin

# if defined DEBUG
  # define debug_export so_export
  # define debug_import so_import
# else
  # define debug_export
  # define debug_import
# endif

# define countof(array) (sizeof((array))/sizeof((array)[0]))
# define scountof(array) cast(ssize_t)countof(array)

namespace va { [[format_va_printf(1)]] static inline FUNC non_exit_fail_with_msg(const char8_t* format, va_list_t args) -> int_t {
  if (1) {
    va_list syslog_args;
    va_copy(syslog_args, args);
    vsyslog(LOG_ERR, format, syslog_args);
  }
  vfprintf(stderr, format, args);
  return EXIT_FAILURE;
}}
[[format_printf(1)]] static inline FUNC non_exit_fail_with_msg(const char8_t* format, ...) -> int_t {
  va_list_t args;
  va_start(args, format);
  int_t val = va::non_exit_fail_with_msg(format, args);
  va_end(args);
  return val;
}
namespace va { [[noreturn]] [[format_va_printf(1)]] static inline FUNC exit_fail_with_msg(const char8_t* format, va_list_t args) -> void {
  exit(va::non_exit_fail_with_msg(format, args));
}}
[[noreturn]] [[format_printf(1)]] static inline FUNC exit_fail_with_msg(const char8_t* format, ...) -> void {
  va_list_t args;
  va_start(args, format);
  va::exit_fail_with_msg(format, args);
  va_end(args);
}
# if !defined USE
  # define    USE(v) cast(void)v
# endif

inline FUNC dkt_normalize_compare_result(intmax_t n) -> cmp_t { return (n < 0) ? -1 : (n > 0) ? 1 : 0; }
inline FUNC intptr_compare(intptr_t i1, intptr_t i2) -> cmp_t { return (i1 < i2) ? -1 : (i1 > i2) ? 1 : 0; }

// klass/trait scope
# define METHOD_SIGNATURE(name, args)         (cast(dkt_signature_func_t)(cast(FUNC (*)args -> const signature_t*) __method_signature::name))()
# define KW_ARGS_METHOD_SIGNATURE(name, args) METHOD_SIGNATURE(name, args)
# define SLOTS_METHOD_SIGNATURE(name, args)   METHOD_SIGNATURE(name, args)

// file scope
# define SIGNATURE(name, args)                (cast(dkt_signature_func_t)(cast(FUNC (*)args -> const signature_t*) __signature::name))()
# define SELECTOR_PTR(name, args)             (cast(dkt_selector_func_t) (cast(FUNC (*)args ->       selector_t* ) __selector::name))()
# define SELECTOR(name, args)                *SELECTOR_PTR(name, args)

# define GENERIC_FUNC_PTR_PTR(name, args)     (cast(dkt_generic_func_func_t)(cast(FUNC (*)args -> generic_func_t*) __generic_func_ptr::name))()
# define GENERIC_FUNC_PTR(name, args)        *GENERIC_FUNC_PTR_PTR(name, args)

# define unless(e) if (0 == (e))
# define until(e)  while (0 == (e))

inline FUNC uintstr(char8_t c1, char8_t c2, char8_t c3, char8_t c4) -> uint32_t {
  return ((((cast(uint32_t)cast(uchar8_t) c1) << 24) & 0xff000000) |
          (((cast(uint32_t)cast(uchar8_t) c2) << 16) & 0x00ff0000) |
          (((cast(uint32_t)cast(uchar8_t) c3) <<  8) & 0x0000ff00) |
          (((cast(uint32_t)cast(uchar8_t) c4) <<  0) & 0x000000ff));
}

# if !defined NUL
  # define    NUL cast(char8_t)0
# endif

# if defined DEBUG && defined DK_ENABLE_TRACE_MACROS
  # define DKT_VA_TRACE_BEFORE(signature, method, object, args)               dkt_va_trace_before(signature, method, object, args)
  # define DKT_VA_TRACE_AFTER( signature, method, object, /* result, */ args) dkt_va_trace_after( signature, method, object, args)
  # define DKT_TRACE_BEFORE(signature, method, object, ...)                   dkt_trace_before(   signature, method, object, __VA_ARGS__)
  # define DKT_TRACE_AFTER( signature, method, object, /* result, */ ...)     dkt_trace_after(    signature, method, object, __VA_ARGS__)
  # define DKT_TRACE(statement) statement
# else
  # define DKT_VA_TRACE_BEFORE(signature, method, object, args)
  # define DKT_VA_TRACE_AFTER( signature, method, object, /* result, */ args)
  # define DKT_TRACE_BEFORE(signature, method, object, ...)
  # define DKT_TRACE_AFTER( signature, method, object, /* result, */ ...)
  # define DKT_TRACE(statement)
# endif

# if defined DKT_USE_MAKE_MACRO
  # if defined DEBUG
    # define make(kls, ...) dk::init(dk::alloc(kls, __FILE__, __LINE__), __VA_ARGS__)
  # else
    # define make(kls, ...) dk::init(dk::alloc(kls), __VA_ARGS__)
  # endif
# endif

// width of hex string representation of a uintptr-t
# define PRIxPTR_WIDTH cast(int_t)(2 * sizeof(uintptr_t))

extern object_t null       [[so_export]] [[read_only]];
extern object_t std_input  [[so_export]];
extern object_t std_output [[so_export]];
extern object_t std_error  [[so_export]];

extern THREAD_LOCAL const signature_t* dkt_current_signature [[so_export]];
extern THREAD_LOCAL super_t            dkt_null_context      [[so_export]];
extern THREAD_LOCAL super_t            dkt_current_context   [[so_export]];

typealias dkt_signature_func_t =    FUNC (*)() -> const signature_t*; // ro
typealias dkt_selector_func_t =     FUNC (*)() -> selector_t*;        // rw
typealias dkt_generic_func_func_t = FUNC (*)() -> generic_func_t*;    // rw

namespace hash { typealias slots_t = size_t; } typealias hash_t = hash::slots_t;

constexpr FUNC dk_hash(str_t str) -> hash_t { // Daniel J. Bernstein
  return !*str ? cast(hash_t)5381 : cast(hash_t)(*str) ^ (cast(hash_t)33 * dk_hash(str + 1));
}
constexpr FUNC dk_hash_switch(str_t str) -> hash_t { return dk_hash(str); }

constexpr FUNC dk_hash_switch(ssize_t val) -> ssize_t { return val; }
constexpr FUNC dk_hash_switch(size_t  val) -> size_t  { return val; }

[[so_export]] FUNC dk_intern(str_t)      -> symbol_t;
[[so_export]] FUNC dk_intern_free(str_t) -> symbol_t;
[[so_export]] FUNC dk_klass_for_name(symbol_t) -> object_t;

[[so_export]] FUNC map(object_t, method_t)   -> object_t;
[[so_export]] FUNC map(object_t[], method_t) -> object_t;

[[so_export]] FUNC dkt_register_info(named_info_t*)   -> void;
[[so_export]] FUNC dkt_deregister_info(named_info_t*) -> void;

// [[so_export]]              FUNC dk-va-add-all(object-t self, va-list-t args) -> object-t;
// [[so_export]] [[sentinel]] FUNC dk-add-all(object-t self, ...)               -> object-t;

[[so_export]] FUNC dk_register_klass(named_info_t*) -> object_t;
[[so_export]] FUNC dk_init_runtime() -> void;
[[so_export]] FUNC dk_make_simple_klass(symbol_t name, symbol_t superklass_name, symbol_t klass_name) -> object_t;

[[so_export]] FUNC dkt_capture_current_exception(object_t arg) -> object_t;
[[so_export]] FUNC dkt_capture_current_exception(str_t arg, str_t src_file, int_t src_line) -> str_t;

[[so_export]] FUNC dk_va_make_named_info_slots(symbol_t name, va_list_t args) -> named_info_t*;
[[so_export]] FUNC dk_va_make_named_info(      symbol_t name, va_list_t args) -> object_t;

[[so_export]] [[sentinel]] FUNC dk_make_named_info_slots(symbol_t name, ...) -> named_info_t*;
[[so_export]] [[sentinel]] FUNC dk_make_named_info(      symbol_t name, ...) -> object_t;

[[debug_export]] FUNC dkt_dump(object_t) -> object_t;
[[debug_export]] FUNC dkt_dump_named_info(named_info_t*) -> named_info_t*;

# if 0
  # define DKT_NULL_METHOD nullptr
# else
  # define DKT_NULL_METHOD cast(method_t)dkt_null_method
# endif

[[so_export]] [[noreturn]] FUNC dkt_null_method(object_t, ...) -> void;

[[debug_export]] FUNC dkt_va_trace_before(const signature_t*, method_t, object_t, va_list_t) -> int_t;
[[debug_export]] FUNC dkt_va_trace_before(const signature_t*, method_t, super_t,  va_list_t) -> int_t;
[[debug_export]] FUNC dkt_va_trace_after( const signature_t*, method_t, object_t, va_list_t) -> int_t;
[[debug_export]] FUNC dkt_va_trace_after( const signature_t*, method_t, super_t,  va_list_t) -> int_t;

[[debug_export]] FUNC dkt_trace_before(const signature_t*, method_t, super_t,  ...) -> int_t;
[[debug_export]] FUNC dkt_trace_before(const signature_t*, method_t, object_t, ...) -> int_t;
[[debug_export]] FUNC dkt_trace_after( const signature_t*, method_t, super_t,  ...) -> int_t;
[[debug_export]] FUNC dkt_trace_after( const signature_t*, method_t, object_t, ...) -> int_t;

[[debug_export]] FUNC dkt_get_klass_chain(object_t kls, char8_t* buf, ssize_t buf_len) -> char8_t*;

[[debug_export]] FUNC dkt_dump_methods(object_t)        -> ssize_t;
[[debug_export]] FUNC dkt_dump_methods(klass::slots_t*) -> ssize_t;

[[debug_export]] FUNC dkt_unbox_check(object_t object, object_t kls) -> void;
