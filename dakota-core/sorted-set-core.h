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

KLASS_NS sorted_set_core {
  FUNC create(ssize_t capacity, ssize_t size, std_compare_t compare, bool_t is_ptr) -> slots_t*;
  FUNC destroy(slots_t* slots) -> std::nullptr_t;

  FUNC add(slots_t* t, const void* key) -> const void*;
  FUNC add_at(slots_t* t, ssize_t offset, const void* key) -> const void*;

  FUNC result_at(const slots_t* t, const void* key) -> result_t;
  FUNC at(const slots_t* t, ssize_t offset) -> const void*;

  FUNC remove(slots_t* t, const void* key) -> const void*;
  FUNC remove_at(slots_t* t, ssize_t offset) -> const void*;
  FUNC remove_first(slots_t* t) -> const void*;
  FUNC remove_last(slots_t* t) -> const void*;

  FUNC first(slots_t* t) -> const void*;
  FUNC last(slots_t* t) -> const void*;

  FUNC sort(slots_t* t) -> slots_t*;
}
