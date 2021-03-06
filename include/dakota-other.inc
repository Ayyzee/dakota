// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// Copyright (C) 2007 - 2017 Robert Nielsen <robert@dakota.org>
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
# include <functional>
# include <limits>
# include <new> // std::bad-alloc
# include <tuple>

# include <syslog.h>
# include <cxxabi.h>

# include <dakota-finally.h>

# define ssizeof(t) (cast(ssize_t)sizeof(t))

# define DKT_MEM_MGMT_MALLOC 0
# define DKT_MEM_MGMT_NEW    1
# define DKT_MEM_MGMT        DKT_MEM_MGMT_MALLOC

# if !defined NUL
  # define    NUL cast(char_t)0
# endif

# if defined __GNUC__
namespace dkt { inline FUNC demangle(str_t mangled_name, char_t* buffer = nullptr, size_t buffer_len = 0) -> str_t {
  int_t status = 0;
  str_t result = abi::__cxa_demangle(mangled_name, buffer, &buffer_len, &status); // must be free()ed if buffer is non-nullptr
  if (status != 0)
    result = mangled_name; // silent failure
  return result;
}}
namespace dkt { inline FUNC demangle_free(str_t name) -> void {
  free(cast(ptr_t)name);
  return;
}}
# else // does nothing if not gcc/clang (g++/clang++)
namespace dkt { inline FUNC demangle(str_t mangled_name, char_t* buffer = nullptr, size_t buffer_len = 0) -> str_t {
  return name;
}}
namespace dkt { inline FUNC demangle_free(str_t name) -> void {
  return;
}}
# endif

namespace dkt { inline FUNC dealloc(ptr_t ptr) -> std::nullptr_t {
# if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
  broken
# elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
  free(ptr);
# else
  # error DK_MEM_MGMT
# endif
  return nullptr;
}}
namespace dkt { inline FUNC alloc(ssize_t size) -> ptr_t {
  ptr_t buf;
# if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
  broken
# elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
  buf = malloc(cast(size_t)size);

  if (buf == nullptr)
    throw std::bad_alloc();
# else
  # error DK_MEM_MGMT
# endif
  memset(buf, 0, cast(size_t)size);
  return buf;
}}
namespace dkt { inline FUNC alloc(ssize_t size, ptr_t ptr) -> ptr_t {
  ptr_t buf;
# if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
  broken
# elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
  buf = realloc(ptr, cast(size_t)size);

  if (buf == nullptr)
    throw std::bad_alloc();
# else
  # error DK_MEM_MGMT
# endif
  return buf;
}}
# if defined DEBUG
  # include <typeinfo>
  # define DKT_UNBOX_CHECK_ENABLED 1
  # define DEBUG_STMT(...) __VA_ARGS__
  # define INTERNED_DEMANGLED_TYPEID_NAME(t) dk_intern_free(dkt::demangle(typeid(t).name()))
# else
  # define DEBUG_STMT(...)
  # define INTERNED_DEMANGLED_TYPEID_NAME(t) nullptr
# endif

# if defined DEBUG
  # define debug_export so_export
  # define debug_import so_import
# else
  # define debug_export
  # define debug_import
# endif

# define countof(array) (sizeof((array))/sizeof((array)[0]))
# define scountof(array) cast(ssize_t)countof(array)

[[format_va_printf(1)]] inline FUNC non_exit_fail_with_msg(const char_t* format, va_list_t args) -> int_t {
  if (1) {
    va_list syslog_args;
    va_copy(syslog_args, args);
    vsyslog(LOG_ERR, format, syslog_args);
  }
  vfprintf(stderr, format, args);
  return EXIT_FAILURE;
}
[[format_printf(1)]] inline FUNC non_exit_fail_with_msg(const char_t* format, ...) -> int_t {
  va_list_t args;
  va_start(args, format);
  int_t val = non_exit_fail_with_msg(format, args);
  va_end(args);
  return val;
}
[[format_va_printf(1), noreturn]] inline FUNC exit_fail_with_msg(const char_t* format, va_list_t args) -> void {
  exit(non_exit_fail_with_msg(format, args));
}
[[format_printf(1), noreturn]] inline FUNC exit_fail_with_msg(const char_t* format, ...) -> void {
  va_list_t args;
  va_start(args, format);
  exit_fail_with_msg(format, args);
  va_end(args);
}
inline FUNC getenv_int(str_t lhs) -> int_t {
  int_t rhs = 0;
  str_t rhs_str = getenv(lhs);

  if (rhs_str != nullptr && rhs_str[0] != NUL && strcmp(rhs_str, "0x0"))
    rhs = atoi(rhs_str);
  return rhs;
}
inline FUNC setenv_int(str_t lhs, int_t rhs, int overwrite = 1) -> int_t { // overwrite by default
  char_t rhs_str[sizeof(int_t) * 3] = "";
  sprintf(rhs_str, "%i", rhs);
  return setenv(lhs, rhs_str, overwrite);
}
# if !defined USE
  # define    USE(v) cast(void)v
# endif

inline FUNC dkt_normalize_compare_result(intmax_t n) -> cmp_t { return (n < 0) ? -1 : (n > 0) ? 1 : 0; }
template<typename T> inline FUNC dk_cmp(T a, T b)    -> cmp_t { return (a < b) ? -1 : (a > b) ? 1 : 0; }

// klass/trait scope
# define METHOD_SIGNATURE(name, args)         (cast(dkt_signature_func_t)(cast(FUNC (*)args -> const signature_t*) __method_signature::name))()
# define KW_ARGS_METHOD_SIGNATURE(name, args) METHOD_SIGNATURE(name, args)
# define SLOTS_METHOD_SIGNATURE(name, args)   METHOD_SIGNATURE(name, args)

// file scope
# define signature(name, args)                (cast(dkt_signature_func_t)(cast(FUNC (*)args -> const signature_t*) __signature::name))()
# define SELECTOR_PTR(name, args)             (cast(dkt_selector_func_t) (cast(FUNC (*)args ->       selector_t* ) __selector::name))()
# define selector(name, args)                *SELECTOR_PTR(name, args)

# define GENERIC_FUNC_PTR_PTR(name, args)     (cast(dkt_generic_func_func_t)(cast(FUNC (*)args -> generic_func_t*) __generic_func_ptr::name))()
# define GENERIC_FUNC_PTR(name, args)        *GENERIC_FUNC_PTR_PTR(name, args)

# define unless(e) if ((e) == 0)
# define until(e)  while ((e) == 0)

inline FUNC uintstr(char_t c1, char_t c2, char_t c3, char_t c4) -> uint32_t {
  return ((((cast(uint32_t)cast(uchar_t) c1) << (32 -  8)) & 0xff000000) |
          (((cast(uint32_t)cast(uchar_t) c2) << (32 - 16)) & 0x00ff0000) |
          (((cast(uint32_t)cast(uchar_t) c3) << (32 - 24)) & 0x0000ff00) |
          (((cast(uint32_t)cast(uchar_t) c4) << (32 - 32)) & 0x000000ff));
}
inline FUNC uintstr(char_t c1, char_t c2, char_t c3, char_t c4,
                    char_t c5, char_t c6, char_t c7, char_t c8) -> uint64_t {
  return ((((cast(uint64_t)cast(uchar_t) c1) << (64 -  8)) & 0xff00000000000000) |
          (((cast(uint64_t)cast(uchar_t) c2) << (64 - 16)) & 0x00ff000000000000) |
          (((cast(uint64_t)cast(uchar_t) c3) << (64 - 24)) & 0x0000ff0000000000) |
          (((cast(uint64_t)cast(uchar_t) c4) << (64 - 32)) & 0x000000ff00000000) |
          (((cast(uint64_t)cast(uchar_t) c5) << (64 - 40)) & 0x00000000ff000000) |
          (((cast(uint64_t)cast(uchar_t) c6) << (64 - 48)) & 0x0000000000ff0000) |
          (((cast(uint64_t)cast(uchar_t) c7) << (64 - 56)) & 0x000000000000ff00) |
          (((cast(uint64_t)cast(uchar_t) c8) << (64 - 64)) & 0x00000000000000ff));
}

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

# if defined DEBUG
  # define make(kls, ...) $init($alloc(kls, __FILE__, __LINE__), __VA_ARGS__)
# else
  # define make(kls, ...) $init($alloc(kls), __VA_ARGS__)
# endif

// width of hex string representation of a uintptr-t
# define PRIxPTR_WIDTH cast(int_t)(2 * sizeof(uintptr_t))

[[so_export, read_only]] extern object_t null;
[[so_export]] extern object_t std_input;  // read-only?
[[so_export]] extern object_t std_output; // read-only?
[[so_export]] extern object_t std_error;  // read-only?

[[so_export]] extern thread_local const signature_t* dkt_current_signature;
[[so_export]] extern thread_local object_t           dkt_current_context_klass;

# if    INT_MAX == INT32_MAX
  typealias  int_t =  int32_t; //  int :: =>  int32 :: / klass  int => klass  int32
  typealias uint_t = uint32_t; // uint :: => uint32 :: / klass uint => klass uint32
# elif  INT_MAX == INT64_MAX
  typealias  int_t =  int64_t; //  int :: =>  int64 :: / klass  int => klass  int64
  typealias uint_t = uint64_t; // uint :: => uint64 :: / klass uint => klass uint64
# else
  # error "Unable to alias int-t and uint-t."
# endif

typealias dkt_signature_func_t =    FUNC (*)() -> const signature_t*; // ro
typealias dkt_selector_func_t =     FUNC (*)() -> selector_t*;        // rw
typealias dkt_generic_func_func_t = FUNC (*)() -> generic_func_t*;    // rw

namespace hash { typealias slots_t = size_t; } typealias hash_t = hash::slots_t;

constexpr FUNC dk_hash(str_t str) -> hash_t { // Daniel J. Bernstein
  return !*str ? cast(hash_t)5381 : cast(hash_t)(*str) ^ (cast(hash_t)33 * dk_hash(str + 1));
}
constexpr FUNC dk_hash_switch(str_t str) -> hash_t { return dk_hash(str); }

constexpr FUNC dk_hash_switch(ssize_t val) -> ssize_t { return val; }
constexpr FUNC dk_hash_switch(size_t  val) ->  size_t { return val; }

constexpr FUNC dk_hash_switch(int_t  val) ->  int_t { return val; }
constexpr FUNC dk_hash_switch(uint_t val) -> uint_t { return val; }

[[so_export]] FUNC dk_intern(str_t)      -> symbol_t;
[[so_export]] FUNC dk_intern_free(str_t) -> symbol_t;
[[so_export]] FUNC dk_klass_for_name(symbol_t) -> object_t;

[[so_export]] FUNC map(object_t,   std::function<object_t (object_t)>) -> object_t;
[[so_export]] FUNC map(object_t[], std::function<object_t (object_t)>) -> object_t;

[[so_export]] FUNC dkt_register_info(named_info_t*)   -> void;
[[so_export]] FUNC dkt_deregister_info(named_info_t*) -> void;

[[so_export]] FUNC dkt_abs_path_containing_addr(ptr_t addr) -> str_t;
[[so_export]] FUNC dkt_file_type_containing_addr(ptr_t addr) -> symbol_t;

// [[so_export]]           FUNC dk-va-add-all(object-t self, va-list-t args) -> object-t;
// [[so_export, sentinel]] FUNC dk-add-all(object-t self, ...)               -> object-t;

[[so_export]] FUNC dk_register_klass(named_info_t*) -> symbol_t;
[[so_export]] FUNC dk_init_runtime() -> void;
[[so_export]] FUNC dk_make_simple_klass(symbol_t name, symbol_t superklass_name, symbol_t klass_name) -> object_t;

[[so_export]]           FUNC dk_va_make_named_info(symbol_t name, va_list_t args) -> named_info_t*;
[[so_export, sentinel]] FUNC dk_make_named_info(symbol_t name, ...) -> named_info_t*;

[[debug_export]] FUNC dkt_dump(object_t) -> object_t;
[[debug_export]] FUNC dkt_dump_named_info(const named_info_t*) -> const named_info_t*;

# if 0
  # define DKT_NULL_METHOD cast(method_t)nullptr
# else
  # define DKT_NULL_METHOD dkt_null_method
# endif

[[so_export]] FUNC dkt_null_method(object_t) -> object_t;

[[debug_export]] FUNC dkt_va_trace_before(const signature_t*, method_t, object_t, va_list_t) -> int_t;
[[debug_export]] FUNC dkt_va_trace_before(const signature_t*, method_t, super_t,  va_list_t) -> int_t;
[[debug_export]] FUNC dkt_va_trace_after( const signature_t*, method_t, object_t, va_list_t) -> int_t;
[[debug_export]] FUNC dkt_va_trace_after( const signature_t*, method_t, super_t,  va_list_t) -> int_t;

[[debug_export]] FUNC dkt_trace_before(const signature_t*, method_t, super_t,  ...) -> int_t;
[[debug_export]] FUNC dkt_trace_before(const signature_t*, method_t, object_t, ...) -> int_t;
[[debug_export]] FUNC dkt_trace_after( const signature_t*, method_t, super_t,  ...) -> int_t;
[[debug_export]] FUNC dkt_trace_after( const signature_t*, method_t, object_t, ...) -> int_t;

[[debug_export]] FUNC dkt_get_klass_chain(object_t kls, char_t* buf, ssize_t buf_len) -> char_t*;

[[debug_export]] FUNC dkt_dump_methods(object_t)              -> ssize_t;
[[debug_export]] FUNC dkt_dump_methods(const klass::slots_t*) -> ssize_t;
