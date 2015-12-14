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

# if !defined dkt_dakota_private_hh
# define      dkt_dakota_private_hh

# include "dakota-dummy.hh"
# include "dakota.hh"

dkt_declare_klass_type_struct(selector_node);
//dkt_declare_klass_type_struct(signature);

FUNC import_selectors(signature_t** signatures, selector_node_t* selector_nodes) -> void;

FUNC interposer_name_for_klass_name(symbol_t klass_name) -> symbol_t;
FUNC add_interpose_prop(symbol_t key, symbol_t element) -> void;

FUNC info_for_name(symbol_t) -> named_info_t*;

FUNC safe_strptrcmp(const str_t* sp1, const str_t* sp2) -> int_t;
FUNC safe_strncmp(str_t s1, str_t s2, size_t n) -> int_t;

FUNC safe_strcmp(str_t, str_t) -> int_t;
FUNC safe_strlen(str_t) -> size_t;

FUNC strerror_name(int_t errnum) -> str_t;

FUNC size_from_info(named_info_t* info) -> int64_t;
FUNC offset_from_info(named_info_t* info) -> int64_t;
FUNC name_from_info(named_info_t* info) -> symbol_t;
FUNC klass_name_from_info(named_info_t* info) -> symbol_t;
FUNC superklass_name_from_info(named_info_t* info) -> symbol_t;
FUNC superklass_name_from_info(named_info_t* info, symbol_t name) -> symbol_t;

FUNC default_superklass_name() -> symbol_t;
FUNC default_klass_name() -> symbol_t;

[[noreturn]] FUNC verbose_terminate()  noexcept -> void;
[[noreturn]] FUNC verbose_unexpected() noexcept -> void;
[[noreturn]] FUNC pre_runtime_verbose_terminate() noexcept -> void;
[[noreturn]] FUNC pre_runtime_verbose_unexpected() noexcept -> void;

# endif // dkt_dakota_private_hh
