// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// Copyright (C) 2007-2015 Robert Nielsen <robert@dakota.org>
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

# include <dlfcn.h> // dlopen(), dlclose(), dlinfo()

# define FUNC auto
# define TYPEALIAS using
# define cast(t) (t)

TYPEALIAS str_t = const char*;
TYPEALIAS ptr_t = void*;

static inline FUNC dso_open(str_t name, int mode) -> ptr_t {
  ptr_t result;
# if defined WIN32
# error "not yet implemented on win32"
# else
  result = dlopen(name, mode);
# endif
  return result;
}
static inline FUNC dso_close(ptr_t handle) -> int {
  int result;
# if defined WIN32
# error "not yet implemented on win32"
# else
  result = dlclose(handle);
# endif
  return result;
}
static inline FUNC dso_error() -> str_t {
  str_t result;
# if defined WIN32
# error "not yet implemented on win32"
# else
  result = dlerror();
# endif
  return result;
}
static inline FUNC dso_abs_path_for_handle(ptr_t handle) -> str_t {
  str_t result = nullptr;
  if (nullptr == handle)
    return result;
# if defined __linux__
  struct link_map l_map = {};
  int r = dlinfo(handle, RTLD_DI_LINKMAP, &l_map);
  if (0 == r && nullptr != l_map.l_name)
    result = l_map.l_name;
# elif defined __APPLE__
  for (int32_t i = cast(int32_t)_dyld_image_count(); i >= 0 ; i--) {
    str_t image_name = _dyld_get_image_name(cast(uint32_t)i);
    ptr_t image_handle = dso_open(image_name, RTLD_NOLOAD);
    dso_close(image_handle);
    if (handle == image_handle)
      return image_name;
  }
# endif
  return result;
}
static inline FUNC dso_abs_path_for_name(str_t name) -> str_t {
  str_t abs_path = nullptr;
  ptr_t handle = dso_open(name, RTLD_LAZY | RTLD_LOCAL);
  if (nullptr != handle) {
    abs_path = dso_abs_path_for_handle(handle);
    dso_close(handle);
  }
  return abs_path;
}
