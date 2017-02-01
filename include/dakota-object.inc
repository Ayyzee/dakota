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

struct [[_dkt_typeinfo_]] object_t {
  object::slots_t* object;

  inline FUNC operator->() const -> object::slots_t*;
  inline FUNC operator*()  const -> object::slots_t&;

  inline FUNC add_ref()    -> void;
  inline FUNC remove_ref() -> void;

  explicit inline operator object::slots_t*() const;
  explicit inline operator ptr_t()            const;
  explicit inline operator intptr_t()         const;
  explicit inline operator uintptr_t()        const;
  explicit inline operator bool()             const;

  inline FUNC operator!() const -> bool;
  inline FUNC operator==(const object_t& r) const -> bool;
  inline FUNC operator!=(const object_t& r) const -> bool;
  inline FUNC operator=(const object_t& r) -> object_t&;
  inline object_t(const object_t& r);
  inline object_t(object::slots_t* r = nullptr);
  inline object_t(intptr_t r);
  inline object_t(uintptr_t r);
  inline object_t(std::nullptr_t r);
  inline ~object_t();
};
inline FUNC object_t::operator->() const -> object::slots_t* { return  this->object; }
inline FUNC object_t::operator*()  const -> object::slots_t& { return *this->object; }

inline object_t::operator object::slots_t*() const { return                 this->object; }
inline object_t::operator ptr_t()            const { return cast(ptr_t)     this->object; }
inline object_t::operator intptr_t()         const { return cast(intptr_t)  this->object; }
inline object_t::operator uintptr_t()        const { return cast(uintptr_t) this->object; }
inline object_t::operator bool()             const { return cast(bool)      this->object; }

inline FUNC object_t::operator!() const -> bool {
  return !this->object;
}
inline FUNC object_t::operator==(const object_t& r) const -> bool {
  return this->object == r.object;
}
inline FUNC object_t::operator!=(const object_t& r) const -> bool {
  return this->object != r.object;
}
inline FUNC object_t::operator=(const object_t& r) -> object_t& {
  if (this->object != r.object) {
    if (this->object)
      this->remove_ref();
    this->object = r.object;
    if (this->object)
      this->add_ref();
  }
  return *this;
}
inline object_t::object_t(const object_t& r) {
  this->object = r.object;
  if (this->object)
    this->add_ref();
}
inline object_t::object_t(object::slots_t* r) {
  this->object = r;
  if (this->object)
    this->add_ref();
}
inline object_t::object_t(intptr_t r) {
  this->object = cast(object::slots_t*)r;
  if (this->object)
    this->add_ref();
}
inline object_t::object_t(uintptr_t r) {
  this->object = cast(object::slots_t*)r;
  if (this->object)
    this->add_ref();
}
inline object_t::object_t(std::nullptr_t r) {
  this->object = cast(object::slots_t*)r;
  if (this->object)
    this->add_ref();
}
inline object_t::~object_t() {
  if (this->object)
    this->remove_ref();
}
