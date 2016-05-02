// -*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// Copyright (C) 2007 - 2015 Robert Nielsen <robert@dakota.org>
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

# if !defined dkt-named-info-kt
# define      dkt-named-info-kt

# include "dakota.hh"

klass named-info {
  method compare(object-t self, object-t other) -> int-t;
  method compare(slots-t*  s, slots-t*  other-s) -> int-t;
  func   compare(slots-t** s, slots-t** other-s) -> int-t;
}
# endif