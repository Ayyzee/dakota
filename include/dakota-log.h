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

#if !defined __dakota_log_h__
#define      __dakota_log_h__

#include <syslog.h>
#include <stdarg.h>

enum
  {
    DKT_LOG_ERROR =   3, // same as syslog.h LOG_ERR
    DKT_LOG_WARNING = 4, // same as syslog.h LOG_WARNING
    DKT_LOG_INFO =    6, // same as syslog.h LOG_INFO
    DKT_LOG_DEBUG =   7  // same as syslog.h LOG_DEBUG
  };

typedef char char8_t; // hackhack

import format_va_printf(2) int_t dkt_va_log(uint32_t priority, const char8_t* format, va_list_t args);
import format_printf(   2) int_t dkt_log(   uint32_t priority, const char8_t* format, ...);

#define log_method()     dkt_log(DKT_LOG_DEBUG, "'klass'=>'%s','method'=>'%s','params'=>'%s'", __klass__, __signature__->name, __signature__->parameter_types)
#define log_klass_func() dkt_log(DKT_LOG_DEBUG, "'klass'=>'%s','func'=>'%s'",   __klass__, __func__)
#define log_func()       dkt_log(DKT_LOG_DEBUG, "'func'=>'%s'",      __func__)

namespace dkt
{
  enum log_t
  {
    LOG_NULL =           0,

    LOG_MEM_FOOTPRINT =  1 <<  0,
    LOG_OBJECT_ALLOC =   1 <<  1,
    LOG_INITIAL_FINAL =  1 <<  2,
    LOG_TRACE_RUNTIME =  1 <<  3,

    LOG_ALL = ~0
  };
  const uint32_t log_flags
  = 0;
//= LOG_MEM_FOOTPRINT | LOG_OBJECT_ALLOC | LOG_INITIAL_FINAL | LOG_TRACE_RUNTIME;
}

// #define DKT_LOG_INFO(flags, ...)    if (flags & dkt::log_flags) { syslog(LOG_INFO   |LOG_DAEMON, __VA_ARGS__); }
// #define DKT_LOG_WARNING(flags, ...) if (flags & dkt::log_flags) { syslog(LOG_WARNING|LOG_DAEMON, __VA_ARGS__); }
// #define DKT_LOG_ERROR(flags, ...)   if (flags & dkt::log_flags) { syslog(LOG_ERROR  |LOG_DAEMON, __VA_ARGS__); }
// #define DKT_LOG_DEBUG(flags, ...)   if (flags & dkt::log_flags) { syslog(LOG_DEBUG  |LOG_DAEMON, __VA_ARGS__); }

#define DKT_LOG_INFO(flags, ...)    if (flags & dkt::log_flags) { dkt_log(DKT_LOG_INFO,    __VA_ARGS__); }
#define DKT_LOG_WARNING(flags, ...) if (flags & dkt::log_flags) { dkt_log(DKT_LOG_WARNING, __VA_ARGS__); }
#define DKT_LOG_ERROR(flags, ...)   if (flags & dkt::log_flags) { dkt_log(DKT_LOG_ERROR,   __VA_ARGS__); }
#define DKT_LOG_DEBUG(flags, ...)   if (flags & dkt::log_flags) { dkt_log(DKT_LOG_DEBUG,   __VA_ARGS__); }

#define DKT_LOG_MEM_FOOTPRINT(...) DKT_LOG_INFO(dkt::LOG_MEM_FOOTPRINT, __VA_ARGS__)
#define DKT_LOG_OBJECT_ALLOC(...)  DKT_LOG_INFO(dkt::LOG_OBJECT_ALLOC,  __VA_ARGS__)
#define DKT_LOG_INITIAL_FINAL(...) DKT_LOG_INFO(dkt::LOG_INITIAL_FINAL, __VA_ARGS__)
#define DKT_LOG_TRACE_RUNTIME(...) DKT_LOG_INFO(dkt::LOG_TRACE_RUNTIME, __VA_ARGS__)

#endif // __dakota_log_h__
