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

#if !defined(__log_h__)
#define __log_h__

#include <syslog.h>
#include <stdint.h> // uint32_t
#include <stdarg.h>
#include <errno.h>
#include <string.h>

#if USE_SYSLOG
#else
#include <stdio.h>
#endif

#include "common.h"

#define __format_printf(fmtarg) \
		__attribute__((__format__ (__printf__, fmtarg, fmtarg + 1)))

#define __format_scanf(fmtarg) \
		__attribute__((__format__ (__scanf__, fmtarg, fmtarg + 1)))

namespace mom
{
  enum log_t
  {
    LOG_NULL =              0,

    LOG_CALLBACK_FLAG =     1 <<  0,
    LOG_CHANGE_EVENT_FLAG = 1 <<  1,
    LOG_CONN_FLAG =         1 <<  2,
    LOG_CREATE_FLAG =       1 <<  3,
    LOG_EOF_FLAG =          1 <<  4,
    LOG_FD_FLAG =           1 <<  5,
    LOG_FREE_FLAG =         1 <<  6,
    LOG_HOST_FLAG =         1 <<  7,
    LOG_INVOKE_FLAG =       1 <<  8,
    LOG_IOMUX_FLAG =        1 <<  9,
    LOG_PROC_FLAG =         1 << 10,
    LOG_RCV_MSG_FLAG =      1 << 11,
    LOG_READ_FLAG =         1 << 12,
    LOG_READ_0_FLAG =       1 << 13,
    LOG_SND_MSG_FLAG =      1 << 14,
    LOG_WRITE_FLAG =        1 << 15,
    LOG_WRITE_0_FLAG =      1 << 16,
    LOG_CLOSE_FLAG =        1 << 17,
    LOG_EXEC_CONTEXT_FLAG = 1 << 18,
    LOG_SOCKINFO_FLAG =     1 << 19,
    LOG_SIGINFO_FLAG =      1 << 20,
    LOG_GENERIC_FLAG =      1 << 21,

    LOG_ALL = ~0
  };

  // could be a uint64_t if we need more than 32 logging axis'
  extern noexport uint32_t log_flags;
  export void openlog(const char8_t* ident, int_t logopt, int_t facility);
  export void closelog();
  export void syslog(int_t priority, const char8_t *message, ...) __format_printf(2);
  export void vsyslog(int_t priority, const char8_t *message, va_list_t args);
  export int_t setlogmask(int_t priority_mask);
  noexport void syslog_flush();

  namespace va
  {
    noexport boole_t should_log(mom::log_t flag, va_list_t args);
  }

  noexport boole_t should_log(mom::log_t flag, ...);
} // namespace mom

#if USE_SYSLOG
#define MOM_LOG_INFO(...)    SYS::syslog(LOG_INFO    | LOG_DAEMON, __VA_ARGS__)
#define MOM_LOG_WARNING(...) SYS::syslog(LOG_WARNING | LOG_DAEMON, __VA_ARGS__)
#define MOM_LOG_ERROR(...)   SYS::syslog(LOG_ERR     | LOG_DAEMON, __VA_ARGS__)
#else

#define MOM_LOG_INFO(...)    mom::syslog(LOG_INFO    | LOG_DAEMON, __VA_ARGS__)
#define MOM_LOG_WARNING(...) mom::syslog(LOG_WARNING | LOG_DAEMON, __VA_ARGS__)
#define MOM_LOG_ERROR(...)   mom::syslog(LOG_ERR     | LOG_DAEMON, __VA_ARGS__)
#endif

#define MOM_LOG_ERROR_ERRNO(errno) MOM_LOG_ERROR("%s:%i: error: %s() errno=%i \"%s\"",  __FILE__, __LINE__, __func__, errno, sys::strerror(errno))
#define MOM_LOG_ERROR_DL() MOM_LOG_ERROR("%s:%i: error: %s() \"%s\"",  __FILE__, __LINE__, __func__,  sys::dlerror())

#if 0
#define MOM_LOG_READ_0(...) if ((mom::LOG_READ_0_FLAG & mom::log_flags) && !(mom::LOG_READ_FLAG & mom::log_flags)) { MOM_LOG_INFO(__VA_ARGS__); }
#else
#define MOM_LOG_READ_0(...)
#endif

#if 0
#define MOM_LOG_WRITE_0(...) if ((mom::LOG_WRITE_0_FLAG & mom::log_flags) && !(mom::LOG_WRITE_FLAG & mom::log_flags)) { MOM_LOG_INFO(__VA_ARGS__); }
#else
#define MOM_LOG_WRITE_0(...)
#endif

#if 0
#define MOM_LOG(flags, ...) if (flags & mom::log_flags) { MOM_LOG_INFO(__VA_ARGS__); }
#else
#define MOM_LOG(flags, ...)
#endif

#if 1
#define MOM_LOG_EOF(...) MOM_LOG(mom::LOG_EOF_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_EOF(...)
#endif

#if 1
#define MOM_LOG_CALLBACK(...) MOM_LOG(mom::LOG_CALLBACK_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_CALLBACK(...)
#endif

#if 1
#define MOM_LOG_CLOSE(...) MOM_LOG(mom::LOG_CLOSE_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_CLOSE(...)
#endif

#if 1
#define MOM_LOG_EXEC_CONTEXT(...) MOM_LOG(mom::LOG_EXEC_CONTEXT_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_EXEC_CONTEXT(...)
#endif

#if 1
#define MOM_LOG_SIGINFO(...) MOM_LOG(mom::LOG_SIGINFO_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_SIGINFO(...)
#endif

#if 1
#define MOM_LOG_SOCKINFO(...) MOM_LOG(mom::LOG_SOCKINFO_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_SOCKINFO(...)
#endif

#if 1
#define MOM_LOG_CHANGE_EVENT(...) MOM_LOG(mom::LOG_CHANGE_EVENT_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_CHANGE_EVENT(...)
#endif

#if 1
#define MOM_LOG_INVOKE(...) MOM_LOG(mom::LOG_INVOKE_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_INVOKE(...)
#endif

#if 1
#define MOM_LOG_IOMUX(...) MOM_LOG(mom::LOG_IOMUX_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_IOMUX(...)
#endif

#if 1
#define MOM_LOG_FD(...) MOM_LOG(mom::LOG_FD_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_FD(...)
#endif

#if 1
#define MOM_LOG_READ(...) MOM_LOG(mom::LOG_READ_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_READ(...)
#endif

#if 1
#define MOM_LOG_WRITE(...) MOM_LOG(mom::LOG_WRITE_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_WRITE(...)
#endif

#if 1
#define MOM_LOG_RCV_MSG(...) MOM_LOG(mom::LOG_RCV_MSG_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_RCV_MSG(...)
#endif

#if 1
#define MOM_LOG_SND_MSG(...) MOM_LOG(mom::LOG_SND_MSG_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_SND_MSG(...)
#endif

#if 1
#define MOM_LOG_HOST(...) MOM_LOG(mom::LOG_HOST_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_HOST(...)
#endif

#if 1
#define MOM_LOG_PROC(...) MOM_LOG(mom::LOG_PROC_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_PROC(...)
#endif

#if 1
#define MOM_LOG_CONN(...) MOM_LOG(mom::LOG_CONN_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_CONN(...)
#endif

#if 1
#define MOM_LOG_CREATE(...) MOM_LOG(mom::LOG_CREATE_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_CREATE(...)
#endif

#if 1
#define MOM_LOG_FREE(...) MOM_LOG(mom::LOG_FREE_FLAG, __VA_ARGS__)
#else
#define MOM_LOG_FREE(...)
#endif

// [{ff,null,zero}]{eq,ne}[en]
//
//             ||   eq   |   ne   ||    errno (en)     |
// ============++========+========++===================+
//     -1 (ff) || ffeq   |  ffne  ||  ffeqen  ffneen   |
// ------------++--------+--------++-------------------+
// NULL (null) || nulleq | nullne || nulleqne nullneen |
// ------------++--------+--------++-------------------+

#define eq(m, n)   if ((m) == (n)) { MOM_LOG_ERROR(); }
#define ne(m, n)   if ((m) != (n)) { MOM_LOG_ERROR(); }

#define eqen(m, n) if ((m) == (n)) { MOM_LOG_ERROR_ERRNO(errno); }
#define neen(m, n) if ((m) != (n)) { MOM_LOG_ERROR_ERRNO(errno); }

#define ffeq(n) eq(-1, (n))
#define ffne(n) ne(-1, (n))

#define ffeqen(n) eqen(-1, (n))
#define ffneen(n) neen(-1, (n))

#define nulleq(n) eq(NULL, (n))
#define nullne(n) ne(NULL, (n))

#define nulleqen(n) eqen(NULL, (n))
#define nullneen(n) neen(NULL, (n))

#define zeroeq(n) eq(0, (n))
#define zerone(n) ne(0, (n))

#define zeroeqen(n) eqen(0, (n))
#define zeroneen(n) neen(0, (n))

#define sc(n) ffeqen((n))

#define sc_abort() if (0 != errno) sys::abort()
#define nbsc_abort() if (0 != errno && EWOULDBLOCK != errno) sys::abort()

#define nbsc(n) if ((-1 == (n)) && (EWOULDBLOCK != errno) && (EINPROGRESS != errno)) { MOM_LOG_ERROR_ERRNO(errno); }
#define iomux(n) if ((-1 == (n)) && (EINTR != errno)) { MOM_LOG_ERROR_ERRNO(errno); }

#define match(a,b) if ((a) != (b)) { MOM_LOG_ERROR("%s:%i: error: failed match(%i, %i)",  __FILE__, __LINE__, a, b); }

#endif
