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

# if !defined DKT_UNBOX_CHECK_ENABLED || 0 == DKT_UNBOX_CHECK_ENABLED
  # define DKT_UNBOX_CHECK(object, kls)
# else
  # define DKT_UNBOX_CHECK(object, kls) dkt_unbox_check(object, kls)
# endif

# define THROW throw

[[so_export]] extern thread_local throw_src_t dkt_throw_src;

KLASS_NS object { inline FUNC box(slots_t* arg) -> object_t {
  return object_t{arg};
}}
KLASS_NS object { inline FUNC unbox(object_t obj) -> const slots_t* {
  return obj.object;
}}
KLASS_NS object { inline FUNC mutable_unbox(object_t obj) -> slots_t* {
  return obj.object;
}}
KLASS_NS klass { [[UNBOX_ATTRS]] inline FUNC mutable_unbox(object_t obj) -> slots_t& {
  DKT_UNBOX_CHECK(obj, _klass_); // optional
  slots_t& s = *cast(slots_t*)(cast(uint8_t*)obj + sizeof(object::slots_t));
  return s;
}}
KLASS_NS klass { [[UNBOX_ATTRS]] inline FUNC unbox(object_t obj) -> const slots_t& {
  DKT_UNBOX_CHECK(obj, _klass_); // optional
  const slots_t& s = *cast(slots_t*)(cast(uint8_t*)obj + sizeof(object::slots_t));
  return s;
}}
inline FUNC klass_of(object_t object) -> object_t {
  assert(object != nullptr);
  return object->klass;
}
inline FUNC superklass_of(object_t kls) -> object_t {
  assert(kls != nullptr);
  return klass::unbox(kls).superklass;
}
inline FUNC name_of(object_t kls) -> symbol_t {
  assert(kls != nullptr);
  return klass::unbox(kls).name;
}
inline FUNC klass_for_name(symbol_t name, object_t kls) -> object_t {
  assert(name != nullptr);
  return kls ? kls : dk_klass_for_name(name);
}
inline FUNC klass_with_trait(object_t kls, symbol_t trait) -> object_t {
  assert(kls != nullptr);
  assert(trait != nullptr);
  while (!(kls == nullptr || kls == null)) { // !root-superklass?(kls)
    const symbol_t* traits = klass::unbox(kls).traits;
    while (traits != nullptr && *traits != nullptr) {
      if (trait == *traits++) {
        return kls;
      }
    }
    kls = superklass_of(kls);
  }
  return nullptr;
}
inline auto object_t::add_ref() -> void {
  if (this->object) {
    //printf("%p: %lli++\n", cast(void*)this->object, this->object->ref_count);
    atomic_incr(&this->object->ref_count);
  }
}
inline auto object_t::remove_ref() -> void {
  if (this->object) {
    assert(this->object->ref_count != 0);
    //printf("%p: %lli--\n", cast(void*)this->object, this->object->ref_count);
    atomic_decr(&this->object->ref_count);
    if (this->object->ref_count == 0) {
      //printf("%p dealloc()\n", cast(void*)*this);
      //this->object = cast(object::slots_t*)dkt::dealloc(cast(void*)*this);
    }
  }
}
