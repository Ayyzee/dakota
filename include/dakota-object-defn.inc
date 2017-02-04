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

FUNC $dealloc(object_t) -> object_t;
const int_fast32_t k_dealloc_initiated = -1;
REF_COUNTING_INLINE FUNC object_t::add_ref() -> void {
  if (this->object->ref_count != k_dealloc_initiated) {
# if 1
    if (getenv_int("DKT_ECHO_REF_COUNT")) {
      fprintf(stdout, "%p: %i++\n", cast(ptr_t)this->object, cast(int_fast32_t)this->object->ref_count);
      fflush(stdout);
    }
# endif
    this->object->ref_count++;
  }
}
REF_COUNTING_INLINE FUNC object_t::remove_ref() -> void {
  if (this->object->ref_count != k_dealloc_initiated) {
    assert(this->object->ref_count != 0);
# if 1
    if (getenv_int("DKT_ECHO_REF_COUNT")) {
      fprintf(stdout, "%p: %i--\n", cast(ptr_t)this->object, cast(int_fast32_t)this->object->ref_count);
      fflush(stdout);
    }
# endif
    this->object->ref_count--;
    if (this->object->ref_count == 0) {
      this->object->ref_count = k_dealloc_initiated;
# if defined DEBUG
      echo_stuff(this->object, "dealloc");
# endif
      if (!getenv_int("SKIP_DEALLOC")) {
        $dealloc(*this);
        this->object = dkt::dealloc(this->object);
      }
      this->object = nullptr;
    }
  }
}
REF_COUNTING_INLINE FUNC object_t::operator->() const -> object::slots_t* { return  this->object; }
REF_COUNTING_INLINE FUNC object_t::operator*()  const -> object::slots_t& { return *this->object; }

REF_COUNTING_INLINE object_t::operator object::slots_t*() const { return                 this->object; }
REF_COUNTING_INLINE object_t::operator ptr_t()            const { return cast(ptr_t)     this->object; }
REF_COUNTING_INLINE object_t::operator intptr_t()         const { return cast(intptr_t)  this->object; }
REF_COUNTING_INLINE object_t::operator uintptr_t()        const { return cast(uintptr_t) this->object; }
REF_COUNTING_INLINE object_t::operator bool()             const { return cast(bool)      this->object; }

REF_COUNTING_INLINE FUNC object_t::operator!() const -> bool {
  return !this->object;
}
REF_COUNTING_INLINE FUNC object_t::operator==(const object_t& r) const -> bool {
  return this->object == r.object;
}
REF_COUNTING_INLINE FUNC object_t::operator!=(const object_t& r) const -> bool {
  return this->object != r.object;
}
REF_COUNTING_INLINE FUNC object_t::operator=(const object_t& r) -> object_t& {
  if (this->object != r.object) {
    if (this->object)
      this->remove_ref();
    this->object = r.object;
    if (this->object)
      this->add_ref();
  }
  return *this;
}
REF_COUNTING_INLINE object_t::object_t(const object_t& r) {
  this->object = r.object;
  if (this->object)
    this->add_ref();
}
REF_COUNTING_INLINE object_t::object_t(object::slots_t* r) {
  this->object = r;
  if (this->object)
    this->add_ref();
}
REF_COUNTING_INLINE object_t::object_t(intptr_t r) {
  this->object = cast(object::slots_t*)r;
  if (this->object)
    this->add_ref();
}
REF_COUNTING_INLINE object_t::object_t(uintptr_t r) {
  this->object = cast(object::slots_t*)r;
  if (this->object)
    this->add_ref();
}
REF_COUNTING_INLINE object_t::object_t(std::nullptr_t r) {
  this->object = cast(object::slots_t*)r;
  if (this->object)
    this->add_ref();
}
REF_COUNTING_INLINE object_t::~object_t() {
  if (this->object)
    this->remove_ref();
}
