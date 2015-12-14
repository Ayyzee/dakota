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

# if !defined dkt_sorted_array_hh
# define      dkt_sorted_array_hh

# include "dakota.hh"

namespace sorted_array {
  struct slots_t;

  FUNC   create(int64_t capacity, int64_t size, std_compare_t compare) -> slots_t*;

  FUNC   sort(slots_t* t) -> slots_t*;
  FUNC   intern(slots_t* t, const void* key) -> const void*;
  FUNC   at(slots_t* t, int64_t offset) -> const void*;
  FUNC   remove_last(slots_t* t) -> const void*;

  FUNC   add(slots_t* t, const void* key) -> slots_t*;
  FUNC   bsearch(slots_t* t, const void* key) -> const void*;
  FUNC   remove_at(slots_t* t, const void* key, int64_t offset) -> const void*;
  FUNC   add_at(slots_t* t, const void* key, int64_t offset) -> slots_t*;
}
# endif
