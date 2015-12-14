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

# if !defined dkt_dakota_log_hh
# define      dkt_dakota_log_hh

# include <syslog.h>
# include <stdarg.h>

typedef char char8_t; // hackhack

[[so_export]] [[format_va_printf(2)]] FUNC dkt_va_log(int64_t priority, str_t format, va_list_t args) -> int_t;
[[so_export]] [[format_printf(   2)]] FUNC dkt_log(   int64_t priority, str_t format, ...) -> int_t;

# define log_method()     dkt_log(dkt::k_log_debug, "\"klass\": \"%s\",\"method\": \"%s\",\"params\": \"%s\"", __klass__, __method__->name, __method__->parameter_types)
# define log_klass_func() dkt_log(dkt::k_log_debug, "\"klass\": \"%s\",\"func\": \"%s\"", __klass__, __func__)
# define log_func()       dkt_log(dkt::k_log_debug, "\"func\": \"%s\"", __func__)

namespace dkt {
  enum log_priority_t : uint_t {
    k_log_emergency = LOG_EMERG,
    k_log_alert =     LOG_ALERT,
    k_log_critical =  LOG_CRIT,
    k_log_error =     LOG_ERR,
    k_log_warning =   LOG_WARNING,
    k_log_notice =    LOG_NOTICE,
    k_log_info =      LOG_INFO,
    k_log_debug =     LOG_DEBUG,
  };

  enum log_element_t : uint64_t {
    k_log_null =           0,

    k_log_mem_footprint =  1 <<  0,
    k_log_object_alloc =   1 <<  1,
    k_log_initial_final =  1 <<  2,
    k_log_trace_runtime =  1 <<  3,

    k_log_all = ~(cast(log_element_t)0)
  };
  const uint64_t log_flags = k_log_null;
  //k-log-mem-footprint | k-log-object-alloc | k-log-initial-final | k-log-trace-runtime;
  //k-log-trace-runtime;
}
// #define DKT-LOG-INFO(flags, ...)    if (flags & dkt::log-flags) { syslog(LOG-INFO   |LOG-DAEMON, __VA-ARGS__); }
// #define DKT-LOG-WARNING(flags, ...) if (flags & dkt::log-flags) { syslog(LOG-WARNING|LOG-DAEMON, __VA-ARGS__); }
// #define DKT-LOG-ERROR(flags, ...)   if (flags & dkt::log-flags) { syslog(LOG-ERROR  |LOG-DAEMON, __VA-ARGS__); }
// #define DKT-LOG-DEBUG(flags, ...)   if (flags & dkt::log-flags) { syslog(LOG-DEBUG  |LOG-DAEMON, __VA-ARGS__); }

# define DKT_LOG_INFO(flags, ...)    if (flags & dkt::log_flags) { dkt_log(dkt::k_log_info,    __VA_ARGS__); }
# define DKT_LOG_WARNING(flags, ...) if (flags & dkt::log_flags) { dkt_log(dkt::k_log_warning, __VA_ARGS__); }
# define DKT_LOG_ERROR(flags, ...)   if (flags & dkt::log_flags) { dkt_log(dkt::k_log_error,   __VA_ARGS__); }
# define DKT_LOG_DEBUG(flags, ...)   if (flags & dkt::log_flags) { dkt_log(dkt::k_log_debug,   __VA_ARGS__); }

# define DKT_LOG_MEM_FOOTPRINT(...) DKT_LOG_INFO(dkt::k_log_mem_footprint, __VA_ARGS__)
# define DKT_LOG_OBJECT_ALLOC(...)  DKT_LOG_INFO(dkt::k_log_object_alloc,  __VA_ARGS__)
# define DKT_LOG_INITIAL_FINAL(...) DKT_LOG_INFO(dkt::k_log_initial_final, __VA_ARGS__)
# define DKT_LOG_TRACE_RUNTIME(...) DKT_LOG_INFO(dkt::k_log_trace_runtime, __VA_ARGS__)

# endif // dkt-dakota-log-hh
