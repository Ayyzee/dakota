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

//FUNC $dealloc(object_t) -> object_t;
REF_COUNTING_INLINE FUNC dk_dealloc(object_t obj) -> void;
REF_COUNTING_INLINE FUNC dk_dealloc(object_t obj) -> void {
# if defined DEBUG
  echo_stuff(obj.obj, "dealloc");
# endif
  $dealloc(obj);
  obj.obj = dkt::dealloc(obj.obj);
  return;
}
const int_fast32_t k_dealloc_initiated = -1;
REF_COUNTING_INLINE FUNC object_t::add_ref() -> void {
  if (this->obj && this->obj->ref_count != k_dealloc_initiated) {
    this->obj->ref_count++;
  }
  return;
}
REF_COUNTING_INLINE FUNC object_t::remove_ref() -> void {
  if (this->obj && this->obj->ref_count != k_dealloc_initiated) {
    assert(this->obj->ref_count != 0);
    this->obj->ref_count--;
    if (this->obj->ref_count == 0) {
      this->obj->ref_count = k_dealloc_initiated;
      dk_dealloc(*this);
    }
  }
  return;
}
REF_COUNTING_INLINE FUNC object_t::has_exit_time_dtor() -> void {
  this->add_ref();
  return;
}

REF_COUNTING_INLINE FUNC object_t::operator ->() const -> object::slots_t* { return  this->obj; }
REF_COUNTING_INLINE FUNC object_t::operator *()  const -> object::slots_t& { return *this->obj; }

REF_COUNTING_INLINE object_t::operator object::slots_t*() const { return                 this->obj; }
REF_COUNTING_INLINE object_t::operator ptr_t()            const { return cast(ptr_t)     this->obj; }
REF_COUNTING_INLINE object_t::operator intptr_t()         const { return cast(intptr_t)  this->obj; }
REF_COUNTING_INLINE object_t::operator uintptr_t()        const { return cast(uintptr_t) this->obj; }
REF_COUNTING_INLINE object_t::operator bool_t()           const { return cast(bool_t)    this->obj; }

REF_COUNTING_INLINE FUNC object_t::operator !() const -> bool_t {
  return !this->obj;
}
REF_COUNTING_INLINE FUNC object_t::operator ==(const object_t& r) const -> bool_t {
  return this->obj == r.obj;
}
REF_COUNTING_INLINE FUNC object_t::operator !=(const object_t& r) const -> bool_t {
  return this->obj != r.obj;
}
REF_COUNTING_INLINE FUNC object_t::operator =(const object_t& r) -> object_t& {
  if (this != &r) {
    this->remove_ref();
    this->obj = r.obj;
    this->add_ref();
  }
  return *this;
}
REF_COUNTING_INLINE object_t::object_t(const object_t& r) {
  this->obj = r.obj;
  this->add_ref();
}
REF_COUNTING_INLINE object_t::object_t(object::slots_t* r) {
  this->obj = r;
  this->add_ref();
}
REF_COUNTING_INLINE object_t::object_t(intptr_t r) {
  this->obj = cast(object::slots_t*)r;
  this->add_ref();
}
REF_COUNTING_INLINE object_t::object_t(uintptr_t r) {
  this->obj = cast(object::slots_t*)r;
  this->add_ref();
}
REF_COUNTING_INLINE object_t::object_t() {
  this->obj = nullptr;
}
REF_COUNTING_INLINE object_t::~object_t() {
  this->remove_ref();
}
