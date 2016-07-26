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

# include "dakota.hh"

KLASS_NS sorted_array {
  FUNC   create(ssize_t capacity, ssize_t size, std_compare_t compare) -> slots_t*;

  METHOD search(slots_t* t, const void* key) -> result_t;
  METHOD sort(slots_t* t) -> slots_t*;
  METHOD intern(slots_t* t, const void* key) -> const void*;
  METHOD at(slots_t* t, ssize_t offset) -> const void*;
  METHOD remove_last(slots_t* t) -> const void*;

  METHOD add(slots_t* t, const void* key) -> slots_t*;
  METHOD bsearch(slots_t* t, const void* key) -> const void*;
  METHOD remove_at(slots_t* t, const void* key, ssize_t offset) -> const void*;
  METHOD add_at(slots_t* t, const void* key, ssize_t offset) -> slots_t*;
}
