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

REF_COUNTING_INLINE FUNC weak_object_t::operator ->() const -> object::slots_t* { return  this->obj; }
REF_COUNTING_INLINE FUNC weak_object_t::operator *()  const -> object::slots_t& { return *this->obj; }

REF_COUNTING_INLINE weak_object_t::operator object_t()         const { return object_t{this->obj}; } // convert from weak-object-t to object-t
REF_COUNTING_INLINE weak_object_t::operator object::slots_t*() const { return                 this->obj; }
REF_COUNTING_INLINE weak_object_t::operator ptr_t()            const { return cast(ptr_t)     this->obj; }
REF_COUNTING_INLINE weak_object_t::operator intptr_t()         const { return cast(intptr_t)  this->obj; }
REF_COUNTING_INLINE weak_object_t::operator uintptr_t()        const { return cast(uintptr_t) this->obj; }
REF_COUNTING_INLINE weak_object_t::operator bool_t()           const { return cast(bool_t)    this->obj; }

REF_COUNTING_INLINE FUNC weak_object_t::operator !() const -> bool_t {
  return !this->obj;
}
REF_COUNTING_INLINE FUNC weak_object_t::operator ==(const weak_object_t& r) const -> bool_t {
  return this->obj == r.obj;
}
REF_COUNTING_INLINE FUNC weak_object_t::operator !=(const weak_object_t& r) const -> bool_t {
  return this->obj != r.obj;
}
REF_COUNTING_INLINE FUNC weak_object_t::operator =(const weak_object_t& r) -> weak_object_t& {
  if (this->obj != r.obj) {
    this->obj = r.obj;
  }
  return *this;
}
REF_COUNTING_INLINE weak_object_t::weak_object_t(const weak_object_t& r) {
  this->obj = r.obj;
}
REF_COUNTING_INLINE weak_object_t::weak_object_t(object::slots_t* r) {
  this->obj = r;
}
REF_COUNTING_INLINE weak_object_t::weak_object_t(intptr_t r) {
  this->obj = cast(object::slots_t*)r;
}
REF_COUNTING_INLINE weak_object_t::weak_object_t(uintptr_t r) {
  this->obj = cast(object::slots_t*)r;
}
REF_COUNTING_INLINE weak_object_t::weak_object_t() {
  this->obj = nullptr;
}
REF_COUNTING_INLINE weak_object_t::~weak_object_t() {
}
REF_COUNTING_INLINE weak_object_t::weak_object_t(const object_t& r) { // convert from object-t to weak-object-t
  this->obj = r.obj;
}
