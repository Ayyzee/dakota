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

# include <fcntl.h>
# include <getopt.h> // getopt_long()
# include <sys/param.h> // MAXPATHLEN
# include <unistd.h>

# include <cassert>
# include <cerrno>
# include <cstdio>
# include <cstring>
# include <sys/wait.h>

# include "dummy.hh"
# include "dakota.hh" // format_printf(), format_va_printf()

# include "dso.hh"

enum {
  DAKOTA_CATALOG_HELP = 256,
  DAKOTA_CATALOG_DIRECTORY,
  DAKOTA_CATALOG_EXPORTED_ONLY,
  DAKOTA_CATALOG_ONLY,
  DAKOTA_CATALOG_OUTPUT,
  DAKOTA_CATALOG_OUTPUT_DIRECTORY,
  DAKOTA_CATALOG_PATH_ONLY,
  DAKOTA_CATALOG_RECURSIVE,
  DAKOTA_CATALOG_SILENT,
};
struct opts_t {
  char* directory;
  bool  exported_only;
  char* only; // full or partial (prefix) klass name
  char* output; // path or "" for stdout
  char* output_directory; // path or "" for .
  bool  path_only;
  bool  recursive;
  bool  silent;
};
static opts_t opts = {};

static FUNC usage(str_t progname, option* options) -> int {
  str_t tmp_progname = strrchr(progname, '/');
  if (tmp_progname != nullptr)
    tmp_progname++;
  else
    tmp_progname = progname;
  fprintf(stdout, "usage: %s", tmp_progname);
  int result = 0;

  while (options->name != nullptr) {
    switch (options->has_arg) {
      case no_argument:
        fprintf(stdout, " [--%s]", options->name);
        break;
      case required_argument:
        fprintf(stdout, " [--%s <>]", options->name);
        break;
      case optional_argument:
        fprintf(stdout, " [--%s [<>]]", options->name);
        break;
      default:
        result = -1;
    }
    options++;
  }
  fprintf(stdout, " <> [...]\n");
  return result;
}
static FUNC handle_opts(int* argc, char*** argv) -> void {
  str_t progname = *argv[0];
  int unrecognized_opt_cnt = 0;
  // options descriptor
  static struct option longopts[] = {
    { "help",             no_argument,       nullptr, DAKOTA_CATALOG_HELP },
    { "directory",        required_argument, nullptr, DAKOTA_CATALOG_DIRECTORY },
    { "exported-only",    no_argument,       nullptr, DAKOTA_CATALOG_EXPORTED_ONLY },
    { "only",             required_argument, nullptr, DAKOTA_CATALOG_ONLY },
    { "output",           required_argument, nullptr, DAKOTA_CATALOG_OUTPUT },
    { "output-directory", required_argument, nullptr, DAKOTA_CATALOG_OUTPUT_DIRECTORY },
    { "path-only",        no_argument,       nullptr, DAKOTA_CATALOG_PATH_ONLY },
    { "recursive",        no_argument,       nullptr, DAKOTA_CATALOG_RECURSIVE },
    { "silent",           no_argument,       nullptr, DAKOTA_CATALOG_SILENT },
    { nullptr, 0, nullptr, 0 }
  };
  int opt;

  while ((opt = getopt_long(*argc, *argv, "", longopts, nullptr)) != -1) {
    switch (opt) {
      case DAKOTA_CATALOG_HELP:
        usage(progname, longopts);
        exit(EXIT_SUCCESS);
      case DAKOTA_CATALOG_DIRECTORY:
        opts.directory = optarg;
        break;
      case DAKOTA_CATALOG_EXPORTED_ONLY:
        opts.exported_only = true;
        break;
      case DAKOTA_CATALOG_ONLY:
        opts.only = optarg;
        break;
      case DAKOTA_CATALOG_OUTPUT:
        opts.output = optarg;
        break;
      case DAKOTA_CATALOG_OUTPUT_DIRECTORY:
        opts.output_directory = optarg;
        break;
      case DAKOTA_CATALOG_PATH_ONLY:
        opts.path_only = true;
        break;
      case DAKOTA_CATALOG_RECURSIVE:
        opts.recursive = true;
        break;
      case DAKOTA_CATALOG_SILENT:
        opts.silent = true;
        break;
      default:
        unrecognized_opt_cnt++;
    }
  }
  if (unrecognized_opt_cnt != 0 || (optind == 1 && *argc == 1)) {
    usage(progname, longopts);
    exit(EXIT_FAILURE);
  }
  *argc -= optind;
  *argv += optind;
  return;
}

# include "spawn.cc"

static FUNC setenv_boole(str_t name, bool value, int overwrite) -> int {
  int result = 0;
  if (value)
    result = setenv(name, "1", overwrite);
  else
    unsetenv(name);
  return result;
}
static FUNC file_exists(str_t path, int flags = O_RDONLY) -> bool {
  bool state;
  int fd = open(path, flags);
  if (fd == -1) {
    state = false;
  } else {
    state = true;
    close(fd);
  }
  return state;
}

// 1: try to spawn() path
//    if that fails
// 2: try to dso_open() path

FUNC main(int argc, char** argv) -> int {
  int exit_value = 0;
  handle_opts(&argc, &argv);
  str_t dev_null = "/dev/null";
  char buffer[MAXPATHLEN] = "";
  char* output_pid = buffer;

  if (opts.directory != nullptr) {
    int n = chdir(opts.directory);
    if (n == -1) exit_fail_with_msg("ERROR:8 %s: \"%s\"\n", opts.directory, strerror(errno));
  }
  if (opts.output != nullptr) {
    if (strcmp(dev_null, opts.output) == 0) {
      output_pid = cast(char*)dev_null;
    } else {
      pid_t pid = getpid();
      snprintf(output_pid, sizeof(buffer), "%s-%i", opts.output, pid);
      // create an empty file
      int fd = open(output_pid, O_CREAT | O_TRUNC, 0644);
      if (fd == -1) exit_fail_with_msg("ERROR:7 %s: \"%s\"\n", output_pid, strerror(errno));
      int n = close(fd);
      if (n == -1) exit_value = non_exit_fail_with_msg("ERROR:6 %s: \"%s\"\n", output_pid, strerror(errno));
    }
  }
  int overwrite;
  if (opts.exported_only)
    setenv_boole("DAKOTA_CATALOG_EXPORTED_ONLY", opts.exported_only, overwrite = 1);
  if (!opts.path_only) {
    setenv("DAKOTA_CATALOG_OUTPUT", output_pid, overwrite = 1);

    if (opts.output_directory != nullptr)
      setenv("DAKOTA_CATALOG_OUTPUT_DIRECTORY", opts.output_directory, overwrite = 1);
    if (opts.only != nullptr)
      setenv("DAKOTA_CATALOG_ONLY", opts.only, overwrite = 1);
    if (opts.recursive)
      setenv_boole("DAKOTA_CATALOG_RECURSIVE", opts.recursive, overwrite = 1);
  }
  int i = 0;
  str_t arg = nullptr;
  while ((arg = argv[i++]) != nullptr) {
    if (!opts.path_only) {
      setenv("DKT_NO_INIT_RUNTIME",  "", overwrite = 1);
      setenv("DKT_EXIT_BEFORE_MAIN", "", overwrite = 1);
      setenv("DAKOTA_CATALOG_ARG", arg, overwrite = 1);
      setenv("DAKOTA_CATALOG_ARG_TYPE", "exe", overwrite = 1); // not currently used
    }
    int status = -1;
    if (!opts.path_only) {
      status = spawn(arg);
    }
    if (status == -1) {
      //fprintf(stderr, "errno=%i \"%s\"\n", errno, strerror(errno));
      if (!opts.path_only) {
        unsetenv("DKT_NO_INIT_RUNTIME");
        unsetenv("DKT_EXIT_BEFORE_MAIN");
        setenv("DAKOTA_CATALOG_ARG_TYPE", "lib", overwrite = 1); // not currently used
      }
      ptr_t handle = dso_open(arg, DSO_OPEN_MODE.NOW | DSO_OPEN_MODE.LOCAL);

      // if the shared library is not found in the search path
      // and the argument *could* be relative to the cwd
      if (handle == nullptr && strchr(arg, '/') == nullptr) {
        char rel_arg[MAXPATHLEN] = "";
        strcat(rel_arg, "./");
        strcat(rel_arg, arg);
        if (file_exists(rel_arg))
          handle = dso_open(rel_arg, DSO_OPEN_MODE.NOW | DSO_OPEN_MODE.LOCAL);
      }
      if (handle != nullptr) {
        if (! opts.silent) {
          // str_t l_name = getenv("DKT_SHARED_LIBRARY_PATH");
          str_t l_name = dso_abs_path_for_handle(handle);
          if (l_name != nullptr)
            printf("%s\n", l_name);
          else
            exit_value = non_exit_fail_with_msg("ERROR: %s: %s: \"%s\"\n", "dso_abs_path_for_handle()", arg, dso_error()); // dso_close() failure
        }
        if (dso_close(handle) != 0)
          exit_value = non_exit_fail_with_msg("ERROR: %s: %s: \"%s\"\n", "dso_close()", arg, dso_error()); // dso_close() failure
      } else
        exit_value = non_exit_fail_with_msg("ERROR: %s: %s: \"%s\"\n", "dso_open", arg, dso_error());   // dso_open() failure
    }
  }
  if (opts.output != nullptr) {
    if (output_pid != dev_null) {
      int n = rename(output_pid, opts.output);
      if (n == -1) exit_value = non_exit_fail_with_msg("ERROR:1 %s: \"%s\"\n", opts.output, strerror(errno));
    }
  }
  return exit_value;
}
