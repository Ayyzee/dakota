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

# include <cstdio>  // fprintf(), stdout, stderr
# include <cstdlib> // EXIT_SUCCESS, EXIT_FAILURE, free()
# include <string>
# include <libgen.h> // dirname_r(), basename_r()
//# include <sys/types.h> // sssize_t
# include <unistd.h> // readlink()
# include <sys/param.h> // MAXPATHLEN

# include "dakota-dso.h"

static FUNC recursive_realpath(str_t path) -> str_t {
  str_t result = realpath(path, nullptr); // must free()
  if (strcmp(result, path) != 0)
    return recursive_realpath(result);
  return result;
}
FUNC main(int argc, const str_t argv[]) -> int {
  str_t progname = argv[0];
  int exit_value = EXIT_SUCCESS;
  for (int i = 1; i < argc; i++) {
    str_t arg = argv[i];
    str_t path = dso_abs_path_for_lib_name(arg);
    path = recursive_realpath(path); // must free()
    if (path != nullptr) {
      char name_buf[MAXPATHLEN + 1] = "";
      str_t name = basename_r(path, name_buf);
      if (strcmp(arg, name) != 0) {
        char dir_buf[MAXPATHLEN + 1]  = "";
        char link[MAXPATHLEN + 1]  = "";
        str_t dir = dirname_r(path, dir_buf);
        snprintf(link, sizeof(link) - 1, "%s/%s", dir, arg);
        str_t target = recursive_realpath(link);
        if (target != nullptr) {
          int cmp = strcmp(path, target);
          free((void*)target);
          if (cmp == 0) {
            fprintf(stdout, "%s\n", link);
          } else {
            fprintf(stdout, "%s\n", path);
          }
        } else {
          fprintf(stdout, "%s\n", path);
        }
      } else {
        fprintf(stdout, "%s\n", path);
      }
    } else {
      fprintf(stderr, "%s: error: can't find %s\n", progname, arg);
      exit_value = EXIT_FAILURE;
    }
  }
  return exit_value;
}
