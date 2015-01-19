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

#if !defined __dakota_private_hh__
#define      __dakota_private_hh__

#include "dakota-dummy.hh"
#include "dakota.hh"

dkt_declare_klass_type_struct(selector_node);
//dkt_declare_klass_type_struct(signature);

extern noexport void (*previous_terminate)();
extern noexport void (*previous_unexpected)();

noexport void import_selectors(signature_t** signatures, selector_node_t* selector_nodes);

noexport symbol_t interposer_name_for_klass_name(symbol_t klass_name);
noexport void add_interpose_prop(symbol_t key, symbol_t element);

noexport named_info_node_t* info_for_name(symbol_t);

noexport int_t  safe_strptrcmp(char8_t const* const* sp1, char8_t const* const* sp2);
noexport int_t  safe_strncmp(char8_t const* s1, char8_t const* s2, size_t n);

noexport uint32_t size_from_info(named_info_node_t* info);
noexport uint32_t offset_from_info(named_info_node_t* info);
noexport symbol_t name_from_info(named_info_node_t* info);
noexport symbol_t klass_name_from_info(named_info_node_t* info);
noexport symbol_t superklass_name_from_info(named_info_node_t* info);
noexport symbol_t superklass_name_from_info(named_info_node_t* info, symbol_t name);

noexport symbol_t default_superklass_name();
noexport symbol_t default_klass_name();

noexport void verbose_terminate();
noexport void verbose_unexpected();

#endif // __dakota_private_hh__
