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

KLASS_NS object       { struct [[_dkt_typeinfo_]] slots_t; }
KLASS_NS object       { typealias slots_t = struct slots_t; }
struct [[_dkt_typeinfo_]] object_t {
  object::slots_t* object;
  inline auto operator->() const -> object::slots_t* { return  this->object; }
  inline auto operator*()  const -> object::slots_t& { return *this->object; }

  explicit inline operator intptr_t()               const { return cast(intptr_t)       this->object; }
  explicit inline operator uintptr_t()              const { return cast(uintptr_t)      this->object; }
  explicit inline operator object::slots_t*()       const { return                      this->object; }
  explicit inline operator const object::slots_t*() const { return                      this->object; }
  explicit inline operator int8_t*()                const { return cast(int8_t*)        this->object; }
  explicit inline operator const int8_t*()          const { return cast(const int8_t*)  this->object; }
  explicit inline operator uint8_t*()               const { return cast(uint8_t*)       this->object; }
  explicit inline operator const uint8_t*()         const { return cast(const uint8_t*) this->object; }
  explicit inline operator void*()                  const { return cast(void*)          this->object; }
  explicit inline operator const void*()            const { return cast(const void*)    this->object; }
  explicit inline operator bool()                   const { return this->object != nullptr; }

  inline auto operator==(const object_t& r) const -> bool {
    return this->object == r.object;
  }
  inline auto operator!=(const object_t& r) const -> bool {
    return this->object != r.object;
  }
  inline auto operator=(const object_t& r) -> object_t& {
    this->object = r.object;
    return *this;
  }
  inline object_t(const object_t& r) {
    this->object = r.object;
  }
  inline object_t(object::slots_t* r) {
    this->object = r;
  }
  inline object_t(void* r) {
    this->object = cast(object::slots_t*)r;
  }
  inline object_t(const void* r) {
    this->object = cast(object::slots_t*)r;
  }
  inline object_t(intptr_t r) {
    this->object = cast(object::slots_t*)r;
  }
  inline object_t(uintptr_t r) {
    this->object = cast(object::slots_t*)r;
  }
  inline object_t(std::nullptr_t r = nullptr) {
    this->object = cast(object::slots_t*)r;
  }
  inline ~object_t() {
  }
};
