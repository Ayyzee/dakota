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

# include <cstdio>  // printf(), fprintf(), stderr
# include <cstdlib> // EXIT_SUCCESS, EXIT_FAILURE

# include "dso.hh"

static str_t progname;

static FUNC echo_abs_path_for_lib_name(str_t lib_name) -> int {
  int exit_value = EXIT_SUCCESS;
  str_t abs_path = dso_abs_path_for_lib_name(lib_name);
  printf("%s\n", abs_path ? abs_path : lib_name);
  if (abs_path == nullptr) {
    fprintf(stderr, "%s: error: %s\n", progname, dso_error());
    exit_value = EXIT_FAILURE;
  }
  return exit_value;
}
FUNC main(int argc, const str_t argv[]) -> int {
  progname = argv[0];
  int exit_value = EXIT_SUCCESS;
  for (int i = 1; i < argc; i++)
    exit_value |= echo_abs_path_for_lib_name(argv[i]);
  return exit_value;
}
