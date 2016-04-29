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

# if !defined dkt-sorted-array-hh
# define      dkt-sorted-array-hh

# include "dakota.hh"

klass sorted-array {
  func   create(ssize-t capacity, ssize-t size, std-compare-t compare) -> slots-t*;

  method search(slots-t* t, const void* key) -> result-t;
  method sort(slots-t* t) -> slots-t*;
  method intern(slots-t* t, const void* key) -> const void*;
  method at(slots-t* t, ssize-t offset) -> const void*;
  method remove-last(slots-t* t) -> const void*;

  method add(slots-t* t, const void* key) -> slots-t*;
  method bsearch(slots-t* t, const void* key) -> const void*;
  method remove-at(slots-t* t, const void* key, ssize-t offset) -> const void*;
  method add-at(slots-t* t, const void* key, ssize-t offset) -> slots-t*;
}
# endif
