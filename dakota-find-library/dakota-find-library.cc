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

# include <dlfcn.h>  // dlopen()/dlclose()/dlinfo()
# include <stdint.h>
# include <stdio.h>  // fprintf(), stderr
# include <stdlib.h> // EXIT_SUCCESS, EXIT_FAILURE

# define DARWIN 1

# if DARWIN
  # include <mach-o/dyld.h>
  # include <mach-o/nlist.h>
# endif

# define FUNC auto
# define cast(t) (t)

static const char* progname;

static FUNC abs_path_for_handle(void* handle) -> const char* {
  const char* result = nullptr;
  if (nullptr == handle)
    return result;
# if DARWIN
  for (int32_t i = cast(int32_t)_dyld_image_count(); i >= 0 ; i--) {
    const char* image_name = _dyld_get_image_name(cast(uint32_t)i);
    void* image_handle = dlopen(image_name, RTLD_NOLOAD);
    dlclose(image_handle);
    if (handle == image_handle)
      return image_name;
  }
# else
  struct link_map l_map = {};
  int r = dlinfo(handle, RTLD_DI_LINKMAP, &l_map);
  if (0 == r && nullptr != l_map.l_name)
    result = l_map.l_name;
# endif
  return result;
}
static FUNC abs_path_for_name(const char* name) -> const char* {
  const char* abs_path = nullptr;
  void* handle = dlopen(name, RTLD_LAZY | RTLD_LOCAL);
  if (nullptr != handle) {
    abs_path = abs_path_for_handle(handle);
    dlclose(handle);
  }
  return abs_path;
}
static FUNC echo_abs_path_for_name(const char* name) -> int {
  int exit_value = EXIT_SUCCESS;
  const char* abs_path = abs_path_for_name(name);
  printf("%s\n", nullptr != abs_path ? abs_path : "");
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
