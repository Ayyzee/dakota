// -*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// Copyright (C) 2007 - 2015 Robert Nielsen <robert@dakota.org>
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

# if defined __linux__
  # include <link.h>
  # if ! defined _GNU_SOURCE
    # define _GNU_SOURCE // dlinfo()
  # endif
# elif defined __APPLE__
  # include <stdint.h>
  # include <mach-o/dyld.h> // _dyld_image_count(), _dyld_get_image_name()
  # include <mach-o/nlist.h>
# endif

# include <dlfcn.h> // dlopen(), dlclose(), dlinfo(), dladdr(), struct Dl-info

# include "dso.hh"

# define cast(t) (t)

// http://pubs.opengroup.org/onlinepubs/009695399/basedefs/dlfcn.h.html

// dso_open() mode flags (default contains DSO_OPEN_MODE.NOW)
// this is different (but safer) than dlopen() default mode flags (default contains RTLD_LAZY)

# if defined __linux__
struct dso_info_request_t {
  int_t LINKMAP;
};
const dso_info_request_t DSO_INFO_REQUEST = {
  .LINKMAP = RTLD_DI_LINKMAP,
};
# endif

const dso_open_mode_t DSO_OPEN_MODE = {
  .NOW =  RTLD_NOW,  // default
  .LAZY = RTLD_LAZY, // dlopen() default

  .GLOBAL = RTLD_GLOBAL, // default
  .LOCAL =  RTLD_LOCAL,

  .NOLOAD = RTLD_NOLOAD,
};
const dso_symbol_handle_t DSO_SYMBOL_HANDLE = {
  .DEFAULT = RTLD_DEFAULT,
  .NEXT =    RTLD_NEXT,
};
TYPEALIAS boole_t = bool;
TYPEALIAS uint_t = unsigned int;

static boole_t is_bit_set(int_t word, uint_t pos) {
  boole_t state = word & (1 << pos);
  return state;
}
static boole_t is_bit_set(int_t word, int_t pos) {
  return is_bit_set(word, cast(uint_t)pos);
}
namespace dso_info {
  TYPEALIAS slots_t = Dl_info;
}
TYPEALIAS dso_info_t = dso_info::slots_t;

FUNC dso_open(str_t name, int_t mode) -> ptr_t {
# if defined WIN32
  USE(mode);
  HINSTANCE handle = LoadLibrary(name);
# else
  if (!is_bit_set(mode, DSO_OPEN_MODE.LAZY))
    mode = DSO_OPEN_MODE.NOW;
  ptr_t handle = dlopen(name, mode);
# endif
  return cast(ptr_t)handle;
}
FUNC dso_symbol(ptr_t handle, str_t symbol_name) -> ptr_t {
  ptr_t result;
# if defined WIN32
# error "not yet implemented on win32"
# else
  result = dlsym(handle, symbol_name);
# endif
  return result;
}
FUNC dso_close(ptr_t handle) -> int_t {
  int_t result;
# if defined WIN32
# error "not yet implemented on win32"
# else
  result = dlclose(handle);
# endif
  return result;
}
FUNC dso_error() -> str_t {
  str_t result;
# if defined WIN32
# error "not yet implemented on win32"
# else
  result = dlerror();
# endif
  return result;
}
// returns nullptr if no exact match
FUNC dso_symbol_name_for_addr(ptr_t addr) -> str_t {
  str_t result = nullptr;
# if defined WIN32
# error "not yet implemented on win32"
# else
  dso_info::slots_t dli {};
  if (0 != dladdr(addr, &dli) && (dli.dli_saddr == addr))
    result = dli.dli_sname;
# endif
  return result;
}
FUNC dso_abs_path_for_handle(ptr_t handle) -> str_t {
  str_t result = nullptr;
  if (nullptr == handle)
    return result;
# if defined __linux__
  struct link_map l_map = {};
  int_t r = dlinfo(handle, DSO_INFO_REQUEST.LINKMAP, &l_map);
  if (0 == r && nullptr != l_map.l_name)
    result = l_map.l_name;
# elif defined __APPLE__
  for (int32_t i = cast(int32_t)_dyld_image_count(); i >= 0 ; i++) {
    str_t image_name = _dyld_get_image_name(cast(uint32_t)i);
    ptr_t image_handle = dso_open(image_name, DSO_OPEN_MODE.NOLOAD);
    dso_close(image_handle);
    if (handle == image_handle)
      return image_name;
  }
# endif
  return result;
}
FUNC dso_abs_path_for_lib_name(str_t lib_name) -> str_t {
  str_t abs_path = nullptr;
  ptr_t handle = dso_open(lib_name, DSO_OPEN_MODE.LAZY | DSO_OPEN_MODE.LOCAL);
  if (nullptr != handle) {
    abs_path = dso_abs_path_for_handle(handle);
    dso_close(handle);
  }
  return abs_path;
}
// FUNC dso_abs_path_containing_addr(ptr_t addr) -> str_t {
//   str_t result = nullptr;
// # if defined WIN32
// # error "not yet implemented on win32"
// # else
//   dso_info::slots_t dli {};
//   if (dladdr(addr, &dli))
//     result = dli.dli_fname;
// # endif
//   return result;
// }
