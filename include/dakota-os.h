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

# pragma once

# include <dakota.h>

# if defined __linux__
  inline FUNC dkt_get_segment_data(str_t, void**, size_t*) -> void* {
    return nullptr;
  }
  inline FUNC strsignal_name(int) -> str_t {
    return "not-yet-implimented: strsignal-name(int-t) -> str-t";
  }
# elif defined __APPLE__ && defined __MACH__
  # include <dlfcn.h> // dladdr()
  # include <mach-o/loader.h> // struct mach_header_64, MH_EXECUTE, MH_DYLIB
  # include <mach-o/getsect.h>
  # include <csignal>

  extern void* __dso_handle;

  inline FUNC dkt_get_segment_data(str_t segment, void** addr_out, size_t* size_out) -> void* {
    *addr_out = cast(void*)getsegmentdata(cast(const struct mach_header_64*)&__dso_handle, segment, size_out);
    return *addr_out;
  }
  inline FUNC strsignal_name(int sig) -> str_t {
    return sys_signame[sig];
  }
  inline FUNC dkt_abs_path_containing_addr(ptr_t addr) -> str_t {
    assert(addr != nullptr);
    str_t result = nullptr;
    Dl_info dli = {};
    if (dladdr(addr, &dli))
      result = dli.dli_fname;
    return result;
  }
  inline FUNC dkt_file_type_containing_addr(ptr_t addr) -> str_t {
    assert(addr != nullptr);
    str_t result = nullptr;
    Dl_info dli = {};
    if (dladdr(addr, &dli)) {
      uint32_t type = (cast(const struct mach_header_64*)dli.dli_fbase)->filetype;
      switch (type) {
        case MH_EXECUTE:
          result = "executable";
          break;
        case MH_DYLIB:
          result = "shared-library";
          break;
      }
    }
    return result;
  }
# else
  # error "Neither __linux__ nor (__APPLE__ && __MACH__) are defined."
# endif
