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

struct [[_dkt_typeinfo_]] weak_object_t {
  object::slots_t* object;

  inline FUNC operator->() const -> object::slots_t*;
  inline FUNC operator*()  const -> object::slots_t&;

           inline operator object_t()         const;
  explicit inline operator object::slots_t*() const;
  explicit inline operator ptr_t()            const;
  explicit inline operator intptr_t()         const;
  explicit inline operator uintptr_t()        const;
  explicit inline operator bool()             const;

  inline FUNC operator!() const -> bool;
  inline FUNC operator==(const weak_object_t& r) const -> bool;
  inline FUNC operator!=(const weak_object_t& r) const -> bool;
  inline FUNC operator=(const weak_object_t& r) -> weak_object_t&;
  inline weak_object_t(const weak_object_t& r);
  inline weak_object_t(object::slots_t* r = nullptr);
  inline weak_object_t(intptr_t r);
  inline weak_object_t(uintptr_t r);
  inline weak_object_t(std::nullptr_t r);
  inline ~weak_object_t();
  inline weak_object_t(const object_t& r); // convert from object-t to weak-object-t
};
