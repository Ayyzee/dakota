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

// dso_open() mode flags (default is dso_NOW|dso_LOCAL)
extern int_t dso_LAZY;
extern int_t dso_NOW;
//
extern int_t dso_GLOBAL;
extern int_t dso_LOCAL;

// dso_symbol() pseudo handles
extern ptr_t dso_DEFAULT;
extern ptr_t dso_NEXT;

FUNC dso_open(str_t path, int_t mode) -> ptr_t;
FUNC dso_symbol_name_for_addr(ptr_t addr) -> str_t;
FUNC dso_path_containing_addr(ptr_t addr) -> str_t;
FUNC dso_symbol(ptr_t handle, str_t symbol_name) -> ptr_t;
FUNC dso_close(ptr_t) -> int_t;
FUNC dso_error() -> str_t;

# endif
