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

# include <stdio.h>  // fprintf(), stderr
# include <stdlib.h> // EXIT_SUCCESS, EXIT_FAILURE
# include <dlfcn.h>  // dlopen()/dlclose()/dlinfo()

# define FUNC auto

FUNC main(int argc, const char* const* argv) -> int {
  int exit_value = EXIT_SUCCESS;
  for (int i = 1; i < argc; i++) {
    const char* arg = argv[i];
    void* handle = dlopen(arg, RTLD_LAZY | RTLD_LOCAL);
    if (nullptr != handle) {
      struct link_map l_map = {};
      int r = dlinfo(handle, RTLD_DI_LINKMAP, &l_map);
      if (0 == r && nullptr != l_map.l_name) {
        printf("%s\n", l_map.l_name);
        dlclose(handle);
      } else {
        printf("%s\n", arg);
        fprintf(stderr, "%s: error: %s", argv[0], dlerror());
        exit_value = EXIT_FAILURE;
      }
    } else {
      printf("%s\n", arg);
      fprintf(stderr, "%s: error: %s", argv[0], dlerror());
      exit_value = EXIT_FAILURE;
    }
  }
  return exit_value;
}
