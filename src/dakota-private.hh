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

func import_selectors(signature_t** signatures, selector_node_t* selector_nodes) -> void;

func interposer_name_for_klass_name(symbol_t klass_name) -> symbol_t;
func add_interpose_prop(symbol_t key, symbol_t element) -> void;

func info_for_name(symbol_t) -> named_info_t*;

func safe_strptrcmp(str_t const* sp1, str_t const* sp2) -> int_t;
func safe_strncmp(str_t s1, str_t s2, size_t n) -> int_t;

func safe_strcmp(str_t, str_t) -> int_t;
func safe_strlen(str_t) -> size_t;

func strerror_name(int_t errnum) -> str_t;

func size_from_info(named_info_t* info) -> uint32_t;
func offset_from_info(named_info_t* info) -> uint32_t;
func name_from_info(named_info_t* info) -> symbol_t;
func klass_name_from_info(named_info_t* info) -> symbol_t;
func superklass_name_from_info(named_info_t* info) -> symbol_t;
func superklass_name_from_info(named_info_t* info, symbol_t name) -> symbol_t;

func default_superklass_name() -> symbol_t;
func default_klass_name() -> symbol_t;

[[noreturn]] func verbose_terminate()  noexcept -> void;
[[noreturn]] func verbose_unexpected() noexcept -> void;
[[noreturn]] func pre_runtime_verbose_terminate() noexcept -> void;
[[noreturn]] func pre_runtime_verbose_unexpected() noexcept -> void;

# endif // dkt_dakota_private_hh
