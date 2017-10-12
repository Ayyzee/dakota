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

# define FUNC      auto
# define TYPEALIAS using

# if defined _WIN32 || defined _WIN64
  # define so_import ms::dllimport
  # define so_export ms::dllexport
# else
  # include <dlfcn.h> // struct Dl_info
  # define so_import
  # define so_export gnu::visibility("default")
  TYPEALIAS dso_info_t = Dl_info;
# endif

TYPEALIAS str_t = const char*;
TYPEALIAS ptr_t = void*;
TYPEALIAS int_t = int;

struct dso_open_mode_t {
  // xor
  int_t NOW; // default
  int_t LAZY;

  // xor
  int_t GLOBAL; // default
  int_t LOCAL;

  int_t NOLOAD;
};
struct dso_symbol_handle_t {
  ptr_t DEFAULT;
  ptr_t NEXT;
};
[[so_export]] extern const dso_open_mode_t     DSO_OPEN_MODE;
[[so_export]] extern const dso_symbol_handle_t DSO_SYMBOL_HANDLE;

extern "C" {
  [[so_export]] FUNC dso_open(str_t path, int_t mode) -> ptr_t;
  [[so_export]] FUNC dso_symbol(ptr_t handle, str_t symbol_name) -> ptr_t;
  [[so_export]] FUNC dso_close(ptr_t handle) -> int_t;
  [[so_export]] FUNC dso_error() -> str_t;
  [[so_export]] FUNC dso_symbol_name_for_addr(ptr_t addr) -> str_t;
  [[so_export]] FUNC dso_abs_path_for_handle(ptr_t handle) -> str_t;
  [[so_export]] FUNC dso_abs_path_for_lib_name(str_t lib_name) -> str_t;
  [[so_export]] FUNC dso_abs_path_containing_addr(ptr_t addr) -> str_t;
  [[so_export]] FUNC dso_addr(ptr_t addr, dso_info_t* info) -> int_t;
  [[so_export]] FUNC dso_file_type_containing_addr(ptr_t addr) -> str_t;
}
