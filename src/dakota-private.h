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

#if !defined __dakota_private_h__
#define      __dakota_private_h__

#include <dakota.h>

noexport named_info_node_t* info_for_name(symbol_t);
noexport assoc_node_t* imported_klasses_for_klass(symbol_t);

noexport int_t  safe_strptrcmp(const char8_t* const* sp1, const char8_t* const* sp2);
noexport int_t  safe_strncmp(const char8_t* s1, const char8_t* s2, size_t n);

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

#endif // __dakota_private_h__
