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

struct [[_dkt_typeinfo_]] object_t {
  object::slots_t* object;

  REF_COUNTING_INLINE FUNC operator ->() const -> object::slots_t*;
  REF_COUNTING_INLINE FUNC operator *()  const -> object::slots_t&;

  REF_COUNTING_INLINE FUNC add_ref()    -> void;
  REF_COUNTING_INLINE FUNC remove_ref() -> void;

  REF_COUNTING_INLINE FUNC has_exit_time_dtor() -> void;

  explicit REF_COUNTING_INLINE operator object::slots_t*() const;
  explicit REF_COUNTING_INLINE operator ptr_t()            const;
  explicit REF_COUNTING_INLINE operator intptr_t()         const;
  explicit REF_COUNTING_INLINE operator uintptr_t()        const;
  explicit REF_COUNTING_INLINE operator bool()             const;

  REF_COUNTING_INLINE FUNC operator !() const -> bool;
  REF_COUNTING_INLINE FUNC operator ==(const object_t& r) const -> bool;
  REF_COUNTING_INLINE FUNC operator !=(const object_t& r) const -> bool;
  REF_COUNTING_INLINE FUNC operator =(const object_t& r) -> object_t&;
  REF_COUNTING_INLINE object_t(const object_t& r);
  REF_COUNTING_INLINE object_t(object::slots_t* r = nullptr);
  REF_COUNTING_INLINE object_t(intptr_t r);
  REF_COUNTING_INLINE object_t(uintptr_t r);
  REF_COUNTING_INLINE object_t(std::nullptr_t r);
  REF_COUNTING_INLINE ~object_t();
};
