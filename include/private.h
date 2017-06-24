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

# include "dummy.h"

dkt_declare_klass_type_struct(selector_node);
//dkt-declare-klass-type-struct(signature);

FUNC import_selectors(signature_t** signatures, selector_node_t* selector_nodes) -> void;

FUNC alloc_instance(ssize_t total_size, symbol_t kls_name, symbol_t instance_name = nullptr) -> object::slots_t*;
# if defined DEBUG
FUNC echo_stuff(object::slots_t* instance, str_t action, symbol_t kls_name, symbol_t instance_name = nullptr) -> void;
# endif
FUNC echo_stuff(object::slots_t* instance, str_t action) -> void;
FUNC interposer_name_for_klass_name(symbol_t klass_name) -> symbol_t;
FUNC add_interpose_prop(symbol_t key, symbol_t item) -> void;

FUNC info_for_name(symbol_t) -> named_info_t*;

FUNC safe_strptrcmp(const str_t* sp1, const str_t* sp2) -> int_t;
FUNC safe_strncmp(str_t s1, str_t s2, size_t n) -> int_t;

FUNC safe_strcmp(str_t, str_t) -> int_t;
FUNC safe_strlen(str_t) -> size_t;

FUNC strerror_name(int_t errnum) -> str_t;

FUNC size_from_info(named_info_t* info) -> ssize_t;
FUNC offset_from_info(named_info_t* info) -> ssize_t;
FUNC name_from_info(named_info_t* info) -> symbol_t;
FUNC klass_name_from_info(named_info_t* info) -> symbol_t;
FUNC superklass_name_from_info(named_info_t* info) -> symbol_t;
FUNC superklass_name_from_info(named_info_t* info, symbol_t name) -> symbol_t;

FUNC default_superklass_name() -> symbol_t;
FUNC default_klass_name() -> symbol_t;

FUNC selector_count() -> int64_t;

KLASS_NS object {
  METHOD dump(object_t) -> object_t;
  METHOD instanceQ(object_t, object_t) -> bool_t; // instance?()
}
KLASS_NS klass {
  METHOD init(object_t, named_info_t*) -> object_t;
  METHOD subklassQ(object_t, object_t) -> bool_t; // subklass?()
}
KLASS_NS bit_vector {
  METHOD set_bit(object_t, ssize_t, bool_t) -> object_t;
}
