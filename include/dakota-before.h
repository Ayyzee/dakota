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

#if !defined __dakota_before_klasses_h__
#define      __dakota_before_klasses_h__

typedef boole_t (*type_predicate_t)(int_t);
typedef boole_t   (*equal_predicate_t)(object_t, object_t); //hackhack
typedef int_t  (*compare_t)(object_t, object_t); // comparitor
typedef uintmax_t (*hash_t)(object_t);

import symbol_t dk_intern(const char8_t*);

typedef unsigned char uchar8_t; // move this somewhere else???

constexpr uintmax_t dk_hash(const char8_t* str, uintmax_t h = 0)
{ // Daniel J. Bernstein
  return !str[h] ? 5381 : ( dk_hash(str, h + 1) * 33 ) ^ (uchar8_t)(str[h]);
}

#endif // __dakota_before_klasses_h__
