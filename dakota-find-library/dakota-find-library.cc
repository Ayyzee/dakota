// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// Copyright (C) 2007-2015 Robert Nielsen <robert@dakota.org>
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

# include <stdio.h>  // printf(), fprintf(), stderr
# include <stdlib.h> // EXIT_SUCCESS, EXIT_FAILURE

# include <dlfcn.h> // dlopen(), dlclose(), dlerror()

# include "abs-path-for-dso-handle.hh"

# define FUNC auto

static const char* progname;

static FUNC abs_path_for_name(const char* name) -> const char* {
  const char* abs_path = nullptr;
  void* handle = dlopen(name, RTLD_LAZY | RTLD_LOCAL);
  if (nullptr != handle) {
    abs_path = abs_path_for_dso_handle(handle);
    dlclose(handle);
  }
  return abs_path;
}
static FUNC echo_abs_path_for_name(const char* name) -> int {
  int exit_value = EXIT_SUCCESS;
  const char* abs_path = abs_path_for_name(name);
  printf("%s\n", abs_path ? abs_path : name);
  if (nullptr == abs_path) {
    fprintf(stderr, "%s: error: %s\n", progname, dlerror());
    exit_value = EXIT_FAILURE;
  }
  return exit_value;
}
FUNC main(int argc, const char* const* argv) -> int {
  progname = argv[0];
  int exit_value = EXIT_SUCCESS;
  for (int i = 1; i < argc; i++)
    exit_value |= echo_abs_path_for_name(argv[i]);
  return exit_value;
}
