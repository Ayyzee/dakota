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

  OBJECT_T_INLINE FUNC operator->() const -> object::slots_t*;
  OBJECT_T_INLINE FUNC operator*()  const -> object::slots_t&;

  OBJECT_T_INLINE FUNC add_ref()    -> void;
  OBJECT_T_INLINE FUNC remove_ref() -> void;

  explicit OBJECT_T_INLINE operator object::slots_t*() const;
  explicit OBJECT_T_INLINE operator ptr_t()            const;
  explicit OBJECT_T_INLINE operator intptr_t()         const;
  explicit OBJECT_T_INLINE operator uintptr_t()        const;
  explicit OBJECT_T_INLINE operator bool()             const;

  OBJECT_T_INLINE FUNC operator!() const -> bool;
  OBJECT_T_INLINE FUNC operator==(const object_t& r) const -> bool;
  OBJECT_T_INLINE FUNC operator!=(const object_t& r) const -> bool;
  OBJECT_T_INLINE FUNC operator=(const object_t& r) -> object_t&;
  OBJECT_T_INLINE object_t(const object_t& r);
  OBJECT_T_INLINE object_t(object::slots_t* r = nullptr);
  OBJECT_T_INLINE object_t(intptr_t r);
  OBJECT_T_INLINE object_t(uintptr_t r);
  OBJECT_T_INLINE object_t(std::nullptr_t r);
  OBJECT_T_INLINE ~object_t();
};
