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

# include <getopt.h> // getopt_long()
# include <sys/param.h> // MAXPATHLEN
# include <errno.h>
# include <string.h>
# include <assert.h>
# include <fcntl.h>
# include <stdio.h>
# include <unistd.h>
# include <sys/wait.h>

# include <dlfcn.h>  // dlopen()/dlclose()

# include "dummy.hh"
# include "dakota.hh" // format_printf(), format_va_printf()

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
static opts_t opts {};

static FUNC usage(const char* progname, option* options) -> int {
  const char* tmp_progname = strrchr(progname, '/');
  if (nullptr != tmp_progname)
    tmp_progname++;
  else
    tmp_progname = progname;
  fprintf(stdout, "usage: %s", tmp_progname);
  int result = 0;

  while (nullptr != options->name) {
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
  const char* progname = *argv[0];
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

  while (-1 != (opt = getopt_long(*argc, *argv, "", longopts, nullptr))) {
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
  if (0 != unrecognized_opt_cnt || (1 == optind && 1 == *argc)) {
    usage(progname, longopts);
    exit(EXIT_FAILURE);
  }
  *argc -= optind;
  *argv += optind;
  return;
}

# include "spawn.cc"

static FUNC setenv_boole(const char* name, bool value, int overwrite) -> int {
  int result = 0;
  if (value)
    result = setenv(name, "1", overwrite);
  else
    unsetenv(name);
  return result;
}
static FUNC file_exists(const char* path, int flags = O_RDONLY) -> bool {
  bool state;
  int fd = open(path, flags);
  if (-1 == fd) {
    state = false;
  } else {
    state = true;
    close(fd);
  }
  return state;
}

// 1: try to exec() path
//    if that fails
// 2: try to dlopen() path

FUNC main(int argc, char** argv, char**) -> int {
  int exit_value = 0;
  handle_opts(&argc, &argv);
  const char* dev_null = "/dev/null";
  char buffer[MAXPATHLEN] = "";
  char* output_pid = buffer;

  if (nullptr != opts.directory) {
    int n = chdir(opts.directory);
    if (-1 == n) exit_fail_with_msg("ERROR:8 %s: \"%s\"\n", opts.directory, strerror(errno));
  }
  if (nullptr != opts.output) {
    if (0 == strcmp(dev_null, opts.output)) {
      output_pid = cast(char*)dev_null;
    } else {
      pid_t pid = getpid();
      snprintf(output_pid, sizeof(buffer), "%s-%i", opts.output, pid);
      // create an empty file
      int fd = open(output_pid, O_CREAT | O_TRUNC, 0644);
      if (-1 == fd) exit_fail_with_msg("ERROR:7 %s: \"%s\"\n", output_pid, strerror(errno));
      int n = close(fd);
      if (-1 == n) exit_value = non_exit_fail_with_msg("ERROR:6 %s: \"%s\"\n", output_pid, strerror(errno));
    }
  }
  int overwrite;
  if (opts.exported_only)
    setenv_boole("DAKOTA_CATALOG_EXPORTED_ONLY", opts.exported_only, overwrite = 1);
  if (!opts.path_only) {
    setenv("DAKOTA_CATALOG_OUTPUT", output_pid, overwrite = 1);

    if (nullptr != opts.output_directory)
      setenv("DAKOTA_CATALOG_OUTPUT_DIRECTORY", opts.output_directory, overwrite = 1);
    if (nullptr != opts.only)
      setenv("DAKOTA_CATALOG_ONLY", opts.only, overwrite = 1);
    if (opts.recursive)
      setenv_boole("DAKOTA_CATALOG_RECURSIVE", opts.recursive, overwrite = 1);
  }
  int i = 0;
  const char* arg = nullptr;
  while (nullptr != (arg = argv[i++])) {
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
    if (-1 == status) {
      //fprintf(stderr, "errno=%i \"%s\"\n", errno, strerror(errno));
      if (!opts.path_only) {
        unsetenv("DKT_NO_INIT_RUNTIME");
        unsetenv("DKT_EXIT_BEFORE_MAIN");
        setenv("DAKOTA_CATALOG_ARG_TYPE", "lib", overwrite = 1); // not currently used
      }
      void* handle = dlopen(arg, RTLD_NOW | RTLD_LOCAL);

      // if the shared library is not found in the search path
      // and the argument *could* be relative to the cwd
      if (nullptr == handle && nullptr == strchr(arg, '/')) {
        char rel_arg[MAXPATHLEN] = "";
        strcat(rel_arg, "./");
        strcat(rel_arg, arg);
        if (file_exists(rel_arg))
          handle = dlopen(rel_arg, RTLD_NOW | RTLD_LOCAL);
      }
      if (nullptr != handle) {
        const char* l_name = getenv("DKT_SHARED_LIBRARY_PATH");
        if (nullptr != l_name) {
          if (! opts.silent)
            printf("%s\n", l_name);
        } else
          exit_value = non_exit_fail_with_msg("ERROR: %s: %s: \"%s\"\n", "DKT_SHARED_LIBRARY_PATH", arg, "environment variable not set");
        if (0 != dlclose(handle))
          exit_value = non_exit_fail_with_msg("ERROR: %s: %s: \"%s\"\n", "dlclose()", arg, dlerror()); // dlclose() failure
      } else
        exit_value = non_exit_fail_with_msg("ERROR: %s: %s: \"%s\"\n", "dlopen", arg, dlerror());   // dlopen() failure
    }
  }
  if (nullptr != opts.output) {
    if (dev_null != output_pid) {
      int n = rename(output_pid, opts.output);
      if (-1 == n) exit_value = non_exit_fail_with_msg("ERROR:1 %s: \"%s\"\n", opts.output, strerror(errno));
    }
  }
  return exit_value;
}
