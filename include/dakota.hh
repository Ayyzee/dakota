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

# if !defined dkt_dakota_hh
# define      dkt_dakota_hh

# include <cstddef>
# include <cstdlib>
# include <cstdio>
# include <cstdarg> // va-list
# include <cstdint>
# include <cstring> // memcpy()
# include <cxxabi.h>
# include <new> // std::bad-alloc

# define DKT_MEM_MGMT_MALLOC 0
# define DKT_MEM_MGMT_NEW    1
# define DKT_MEM_MGMT        DKT_MEM_MGMT_MALLOC

# if defined __GNUG__
inline func demangle(str_t mangled_name) -> str_t {
  int status = -1;
  str_t name = abi::__cxa_demangle(mangled_name, 0, 0, &status);
  if (0 == status)
    return name;
  else
    return nullptr;
}
# else // does nothing if not g++
inline func demangle(str_t mangled_name) -> str_t {
  return name;
}
# endif

namespace dkt {
  inline func dealloc(void* ptr) -> void {
# if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
    operator delete(ptr);
# elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
    free(ptr);
# else
    # error DK_MEM_MGMT
# endif
  }
  inline func alloc(std::size_t size) -> void* {
    void* buf;
# if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
    buf = operator new(size);
# elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
    buf = malloc(size);

    if (nullptr == buf)
      throw std::bad_alloc();
# else
    # error DK_MEM_MGMT
# endif
    return buf;
  }
  inline func alloc(std::size_t size, void* ptr) -> void* {
    void* buf;
# if (DKT_MEM_MGMT == DKT_MEM_MGMT_NEW)
    buf = dkt::alloc(size);
    memcpy(buf, ptr, size);
    dkt::dealloc(ptr);
# elif (DKT_MEM_MGMT == DKT_MEM_MGMT_MALLOC)
    buf = realloc(ptr, size);

    if (nullptr == buf)
      throw std::bad_alloc();
# else
    # error DK_MEM_MGMT
# endif
    return buf;
  }
}
# if defined DEBUG
  # define DEBUG_STMT(stmt) stmt
# else
  # define DEBUG_STMT(stmt)
# endif

# define dkt_rodata_section  gnu::section("__DKT_RODATA, __dkt_rodata")
# define format_va_printf(n) gnu::format(__printf__, n, 0)
# define format_va_scanf(n)  gnu::format(__scanf__,  n, 0)
# define format_printf(n)    gnu::format(__printf__, n, n + 1)
# define format_scanf(n)     gnu::format(__scanf__,  n, n + 1)
# define sentinel            gnu::sentinel
# define unused              gnu::unused

# define THREAD_LOCAL __thread // bummer that clang does not support thread-local on darwin

# define unbox_attrs gnu::pure,gnu::hot,gnu::nothrow

# if defined DEBUG
  # define debug_so_export so_export
  # define debug_so_import so_import
# else
  # define debug_so_export
  # define debug_so_import
# endif

# define cast(t) (t)
# define DK_COUNTOF(array) (sizeof((array))/sizeof((array)[0]))

// template <typename T, size-t N>
// constexpr size-t dk-countof(T(&)[N]) {
//   return N;
// }
# if !defined USE
  # define    USE(v) cast(void)v
# endif

# define klass_of(object)   (object)->klass
# define superklass_of(kls) klass::unbox(kls).superklass
# define name_of(kls)       klass::unbox(kls).name

inline func dkt_normalize_compare_result(intmax_t n) -> int_t { return (n < 0) ? -1 : (n > 0) ? 1 : 0; }
// file scope
# define SELECTOR(name, args)                *(cast(dkt_selector_func_t) (cast(selector_t*        (*)args) __selector::name))()
# define SIGNATURE(name, args)                (cast(dkt_signature_func_t)(cast(signature_t const* (*)args) __signature::name))()

// klass/trait scope
# define SLOTS_METHOD_SIGNATURE(name, args)   (cast(dkt_signature_func_t)(cast(signature_t const* (*)args) __slots_method_signature::name))()
# define KW_ARGS_METHOD_SIGNATURE(name, args) (cast(dkt_signature_func_t)(cast(signature_t const* (*)args) __kw_args_method_signature::name))()

# define unless(e) if (0 == (e))
# define until(e)  while (0 == (e))

# define intstr(c1, c2, c3, c4) \
   ((((cast(int32_t)cast(char8_t) c1) << 24) & 0xff000000) | \
    (((cast(int32_t)cast(char8_t) c2) << 16) & 0x00ff0000) | \
    (((cast(int32_t)cast(char8_t) c3) <<  8) & 0x0000ff00) | \
    (((cast(int32_t)cast(char8_t) c4) <<  0) & 0x000000ff))

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

# define PRIxPTR_WIDTH cast(int_t)(2 * sizeof(uintptr_t))

extern object_t null       [[so_export]] [[dkt_rodata_section]];
extern object_t std_input  [[so_export]] [[dkt_rodata_section]];
extern object_t std_output [[so_export]] [[dkt_rodata_section]];
extern object_t std_error  [[so_export]] [[dkt_rodata_section]];

typedef func (*compare_t)(object_t, object_t) -> int_t; // comparitor
typedef func (*dkt_signature_func_t)() -> signature_t const*;
typedef func (*dkt_selector_func_t)() -> selector_t*;

namespace hash { typedef uintptr_t slots_t; } typedef hash::slots_t hash_t;

constexpr func dk_hash(str_t str) -> hash_t { // Daniel J. Bernstein
  return !*str ? cast(hash_t)5381 : cast(hash_t)(*str) ^ (33 * dk_hash(str + 1));
}
constexpr func dk_hash_switch(str_t str) -> hash_t { return dk_hash(str); }

constexpr func dk_hash_switch( intptr_t val) -> intptr_t  { return val; }
constexpr func dk_hash_switch(uintptr_t val) -> uintptr_t { return val; }

[[so_export]] func dk_intern(str_t) -> symbol_t;
[[so_export]] func dk_intern_free(str_t) -> symbol_t;
[[so_export]] func dk_klass_for_name(symbol_t) -> object_t;

[[so_export]] func dkt_register_info(named_info_t*) -> void;
[[so_export]] func dkt_deregister_info(named_info_t*) -> void;

// [[so-export]]              func dk-va-add-all(object-t self, va-list-t) -> object-t;
// [[so-export]] [[sentinel]] func dk-add-all(object-t self, ...) -> object-t;

[[so_export]] func dk_register_klass(named_info_t* klass_info) -> object_t;
[[so_export]] func dk_init_runtime() -> void;
[[so_export]] func dk_make_simple_klass(symbol_t name, symbol_t superklass_name, symbol_t klass_name) -> object_t;

[[so_export]] func dkt_capture_current_exception(object_t arg) -> object_t;
[[so_export]] func dkt_capture_current_exception(str_t arg) -> str_t;

[[so_export]] func dk_va_make_named_info_slots(symbol_t name, va_list_t args) -> named_info_t*;
[[so_export]] func dk_va_make_named_info(      symbol_t name, va_list_t args) -> object_t;

[[so_export]] [[sentinel]] func dk_make_named_info_slots(symbol_t name, ...) -> named_info_t*;
[[so_export]] [[sentinel]] func dk_make_named_info(      symbol_t name, ...) -> object_t;

[[debug_so_export]] func dkt_dump_named_info(named_info_t* info) -> named_info_t*;

//#define DKT-NULL-METHOD nullptr
# define DKT_NULL_METHOD cast(method_t)dkt_null_method

[[so_export]] [[noreturn]] func dkt_null_method(object_t object, ...) -> void;
[[so_export]] func map(object_t, method_t) -> object_t;

[[debug_so_export]] func dkt_va_trace_before(signature_t const* signature, method_t method, object_t object,  va_list_t args) -> int_t;
[[debug_so_export]] func dkt_va_trace_before(signature_t const* signature, method_t method, super_t  context, va_list_t args) -> int_t;
[[debug_so_export]] func dkt_va_trace_after( signature_t const* signature, method_t method, object_t object,  va_list_t args) -> int_t;
[[debug_so_export]] func dkt_va_trace_after( signature_t const* signature, method_t method, super_t  context, va_list_t args) -> int_t;

[[debug_so_export]] func dkt_trace_before(signature_t const* signature, method_t method, super_t  context, ...) -> int_t;
[[debug_so_export]] func dkt_trace_before(signature_t const* signature, method_t method, object_t object,  ...) -> int_t;
[[debug_so_export]] func dkt_trace_after( signature_t const* signature, method_t method, super_t  context, ...) -> int_t;
[[debug_so_export]] func dkt_trace_after( signature_t const* signature, method_t method, object_t object,  ...) -> int_t;

[[debug_so_export]] func dkt_get_klass_chain(object_t klass, char8_t* buf, uint32_t buf_len) -> char8_t*;

[[debug_so_export]] func dkt_dump_methods(object_t) -> void;
[[debug_so_export]] func dkt_dump_methods(klass::slots_t*) -> void;

[[debug_so_export]] func dkt_unbox_check(object_t object, object_t kls) -> void;

# endif // dkt-dakota-hh
