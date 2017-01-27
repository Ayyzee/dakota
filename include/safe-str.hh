// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

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

# pragma once

# include <cstdlib>
# include <cstring>

inline FUNC safe_strcmp(str_t s1, str_t s2) -> int_t {
  int_t value = 0;

  if (s1 == nullptr || s2 == nullptr) {
    if (s1 == nullptr && s2 == nullptr)
      value = 0;
    else if (s1 == nullptr)
      value = -1;
    else if (s2 == nullptr)
      value = 1;
  } else {
    value = dkt_normalize_compare_result(strcmp(s1, s2));
  }
  return value;
}
inline FUNC safe_strptrcmp(const str_t* sp1, const str_t* sp2) -> int_t {
  str_t s1;
  if (sp1 == nullptr)
    s1 = nullptr;
  else
    s1 = *sp1;
  str_t s2;
  if (sp2 == nullptr)
    s2 = nullptr;
  else
    s2 = *sp2;
  return safe_strcmp(s1, s2);
}
inline FUNC safe_strncmp(str_t s1, str_t s2, size_t n) -> int_t {
  int_t value = 0;

  if (s1 == nullptr || s2 == nullptr) {
    if (s1 == nullptr && s2 == nullptr)
      value = 0;
    else if (s1 == nullptr)
      value = -1;
    else if (s2 == nullptr)
      value = 1;
  } else {
    value = dkt_normalize_compare_result(strncmp(s1, s2, n));
  }
  return value;
}
inline FUNC safe_strlen(str_t str) -> size_t {
  size_t len;

  if (str == nullptr)
    len = 0;
  else
    len = strlen(str);
  return len;
}
