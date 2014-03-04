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

#include <dakota.h>

namespace sorted_array
{
  struct slots_t;

  noexport slots_t* create(uint32_t capacity, uint32_t size, std_compare_t compare);

  noexport const void* intern(slots_t* t, const void* key);
  noexport const void* at(slots_t* t, uint32_t offset);
  noexport const void* remove_last(slots_t* t);

  noexport slots_t*    add(slots_t* t, const void* key);
  noexport const void* bsearch(slots_t* t, const void* key);
  noexport const void* remove_at(slots_t* t, const void* key, uint32_t offset);
  noexport slots_t*    add_at(slots_t* t, const void* key, uint32_t offset);
}
