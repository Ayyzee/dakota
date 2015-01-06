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

#include <getopt.h> // getopt_long()
#include <dlfcn.h>  // dlopen()
#include <sys/param.h> // MAXPATHLEN
#include <errno.h>
#include <string.h>
#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>

#define declare_klass_type_struct(k)          namespace k { struct     slots_t; } typedef k::slots_t k##_t
//#define declare_klass_type_union(k)           namespace k { union      slots_t; } typedef k::slots_t k##_t
//#define declare_klass_type_enum(k)            namespace k { enum : int32_t slots_t; } typedef k::slots_t k##_t
#define declare_klass_type_typedef(k, t)      namespace k { typedef t  slots_t; } typedef k::slots_t k##_t
#define declare_klass_type_typedef_func(k, t) namespace k { typedef t;          } typedef k::slots_t k##_t

typedef int int_t;
typedef unsigned int uint_t;

namespace object { struct slots_t; } typedef object::slots_t* object_t;

declare_klass_type_typedef(boole, bool);
declare_klass_type_typedef(char8, char);
declare_klass_type_typedef(selector, uintptr_t);
declare_klass_type_typedef(symbol, const char*);
declare_klass_type_typedef(uchar8, unsigned char);

declare_klass_type_typedef_func(method, object_t (*slots_t)());

declare_klass_type_struct(super);
declare_klass_type_struct(klass);
declare_klass_type_struct(signature);
declare_klass_type_struct(named_info_node);

#include <dakota.h> // format_printf(), format_va_printf()

enum
  {
    DKT_INFO_HELP = 256,
    DKT_INFO_OUTPUT,
    DKT_INFO_OUTPUT_DIRECTORY,
    DKT_INFO_DIRECTORY,
    DKT_INFO_ONLY,
    DKT_INFO_RECURSIVE
  };

struct opts_t
{
  char* only; // full or partial (prefix) klass name
  char* output; // path or "" for stdout
  char* output_directory; // path or "" for .
  char* directory;
  bool  recursive;
};
static opts_t opts;

static int
usage(const char* progname, option* options)
{
  const char* tmp_progname = strrchr(progname, '/');
  if (nullptr != tmp_progname)
    tmp_progname++;
  else
    tmp_progname = progname;
  fprintf(stdout, "usage: %s", tmp_progname);
  int result = 0;

  while (nullptr != options->name)
  {
    switch (options->has_arg)
    {
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

static void
handle_opts(int* argc, char*** argv)
{
  const char* progname = *argv[0];
  int unrecognized_opt_cnt = 0;
  // options descriptor
  static struct option longopts[] =
  {
    { "help",             no_argument,       nullptr, DKT_INFO_HELP },
    { "output",           required_argument, nullptr, DKT_INFO_OUTPUT },
    { "output-directory", required_argument, nullptr, DKT_INFO_OUTPUT_DIRECTORY },
    { "directory",        required_argument, nullptr, DKT_INFO_DIRECTORY },
    { "only",             required_argument, nullptr, DKT_INFO_ONLY },
    { "recursive",        no_argument,       nullptr, DKT_INFO_RECURSIVE },
    { nullptr, 0, nullptr, 0 }
  };
  int opt;

  while (-1 != (opt = getopt_long(*argc, *argv, "", longopts, nullptr)))
  {
    switch (opt)
    {
      case DKT_INFO_HELP:
        usage(progname, longopts);
        exit(EXIT_SUCCESS);
      case DKT_INFO_OUTPUT:
        opts.output = optarg;
        break;
      case DKT_INFO_OUTPUT_DIRECTORY:
        opts.output_directory = optarg;
        break;
      case DKT_INFO_DIRECTORY:
        opts.directory = optarg;
        break;
      case DKT_INFO_ONLY:
        opts.only = optarg;
        break;
      case DKT_INFO_RECURSIVE:
        opts.recursive = true;
        break;
      default:
        unrecognized_opt_cnt++;
    }
  }
  if (0 != unrecognized_opt_cnt || (1 == optind && 1 == *argc))
  {
    usage(progname, longopts);
    exit(EXIT_FAILURE);
  }
  *argc -= optind;
  *argv += optind;
  return;
}

namespace va
{
  [[noreturn]] format_va_printf(3) static void _abort_with_log(const char* file, int line, const char* format, va_list args)
  {
    fprintf(stderr, "%s:%i: ", file, line);
    vfprintf(stderr, format, args);
    abort();
  }
}

[[noreturn]] format_printf(3) static void _abort_with_log(const char* file, int line, const char* format, ...)
{
  va_list args;
  va_start(args, format);
  va::_abort_with_log(file, line, format, args);
  va_end(args);
}

#define abort_with_log(...) _abort_with_log(__FILE__, __LINE__, __VA_ARGS__)

#include "spawn.cc"

static int
setenv_boole(const char* name, bool value, int overwrite)
{
  int result = 0;
  if (value)
    result = setenv(name, "1", overwrite);
  else
    unsetenv(name);
  return result;
}

// 1: try to exec() path
//    if that fails
// 2: try to dlopen() path

int
main(int argc, char** argv, char**)
{
  handle_opts(&argc, &argv);
  char output_pid[MAXPATHLEN] = "";

  if (nullptr != opts.directory)
  {
    int n = chdir(opts.directory);
    if (-1 == n) abort_with_log("ERROR: %s: \"%s\"\n", output_pid, strerror(errno));
  }

  if (nullptr != opts.output)
  {
    pid_t pid = getpid();
    snprintf(output_pid, sizeof(output_pid), "%s-%i", opts.output, pid);

    // create an empty file
    int fd = open(output_pid, O_CREAT | O_TRUNC, 0644);
    if (-1 == fd) abort_with_log("ERROR: %s: \"%s\"\n", output_pid, strerror(errno));
    int n = close(fd);
    if (-1 == n) abort_with_log("ERROR: %s: \"%s\"\n", output_pid, strerror(errno));
  }
  int overwrite;
  setenv("DKT_INFO_OUTPUT", output_pid, overwrite = 1);

  if (nullptr != opts.output_directory)
    setenv("DKT_INFO_OUTPUT_DIRECTORY", opts.output_directory, overwrite = 1);
  if (nullptr != opts.only)
    setenv("DKT_INFO_ONLY", opts.only, overwrite = 1);
  if (opts.recursive)
    setenv_boole("DKT_INFO_RECURSIVE", opts.recursive, overwrite = 1);
  int i = 0;
  const char* arg = nullptr;
  while (nullptr != (arg = argv[i++]))
  {
    setenv("DKT_NO_INIT_RUNTIME",  "", overwrite = 1);
    setenv("DKT_EXIT_BEFORE_MAIN", "", overwrite = 1);
    setenv("DKT_INFO_ARG", arg, overwrite = 1);
    setenv("DKT_INFO_ARG_TYPE", "exe", overwrite = 1); // not currently used
    int status = spawn(arg);
    if (-1 == status)
    {
      //fprintf(stderr, "errno=%i \"%s\"\n", errno, strerror(errno));
      unsetenv("DKT_NO_INIT_RUNTIME");
      unsetenv("DKT_EXIT_BEFORE_MAIN");
      setenv("DKT_INFO_ARG_TYPE", "lib", overwrite = 1); // not currently used
      if (nullptr == strchr(arg, '/'))
      { // not required on darwin (required on linux)
        char arg_path[MAXPATHLEN] = "";
        strcat(arg_path, "./");
        strcat(arg_path, arg);
        arg = arg_path;
      }
      void* handle = dlopen(arg, RTLD_NOW | RTLD_LOCAL);
      if ((nullptr == handle) || (0 != dlclose(handle)))
        abort_with_log("ERROR: %s: \"%s\"\n", arg, dlerror());
    }
  }
  if (nullptr != opts.output)
  {
    int n = rename(output_pid, opts.output);
    if (-1 == n) abort_with_log("ERROR: %s: \"%s\"\n", opts.output, strerror(errno));
  }
  return 0;
}
