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

# pragma once

# include <dakota-decl.hh>

// no generated object::unbox() due to Koenig lookup (AKA: argument dependant lookup)

# if !defined DKT_UNBOX_CHECK_ENABLED || 0 == DKT_UNBOX_CHECK_ENABLED
  # define DKT_UNBOX_CHECK(object, kls)
# else
  # define DKT_UNBOX_CHECK(object, kls) dkt_unbox_check(object, kls)
# endif

KLASS_NS object { inline FUNC box(slots_t* arg) -> object_t {
  return arg;
}}
KLASS_NS klass { [[unbox_attrs]] inline FUNC unbox(object_t object) -> slots_t& {
  DKT_UNBOX_CHECK(object, klass); // optional
  slots_t& s = *cast(slots_t*)(cast(uint8_t*)object + sizeof(object::slots_t));
  return s;
}}
inline FUNC klass_of(object_t object) -> object_t {
  return object->klass;
}
inline FUNC superklass_of(object_t kls) -> object_t {
  return klass::unbox(kls).superklass;
}
inline FUNC name_of(object_t kls) -> symbol_t {
  return klass::unbox(kls).name;
}
