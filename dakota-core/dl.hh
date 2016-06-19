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

# if !defined dkt_dl_hh
# define      dkt_dl_hh

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
extern const dso_open_mode_t     DSO_OPEN_MODE;
extern const dso_symbol_handle_t DSO_SYMBOL_HANDLE;

FUNC dso_open(str_t path, int_t mode) -> ptr_t;
FUNC dso_symbol_name_for_addr(ptr_t addr) -> str_t;
FUNC dso_abs_path_containing_addr(ptr_t addr) -> str_t;
FUNC dso_symbol(ptr_t handle, str_t symbol_name) -> ptr_t;
FUNC dso_close(ptr_t handle) -> int_t;
FUNC dso_error() -> str_t;

# endif
