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

#if !defined common_hxx
#define common_hxx

#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h> // strerror()
#include <errno.h> // errno
#include <limits.h>
#include <syslog.h>
#include <stdarg.h>

#if 1
#define require if(1)
#else
#define require if(0)
#endif

#if 1
#define ensure if(1)
#else
#define ensure if(0)
#endif

#define DK_LOG_ERROR() fprintf(stderr, "%s:%i: error: \"%s\"\n",  __FILE__, __LINE__, strerror(errno))

#define DK_LOG_ERROR_ERRNO() fprintf(stderr, "%s:%i: error: errno=%i \"%s\"\n",  __FILE__, __LINE__, errno, strerror(errno))

// [{ff,null,zero}]{eq,ne}[en]
//
//             ||   eq   |   ne   ||    errno (en)     |
// ============++========+========++===================+
//     -1 (ff) || ffeq   |  ffne  ||  ffeqen  ffneen   |
// ------------++--------+--------++-------------------+
// NULL (null) || nulleq | nullne || nulleqne nullneen |
// ------------++--------+--------++-------------------+

#define eq(m, n)   if ((m) == (n)) { DK_LOG_ERROR(); }
#define ne(m, n)   if ((m) != (n)) { DK_LOG_ERROR(); }

#define eqen(m, n) if ((m) == (n)) { DK_LOG_ERROR_ERRNO(); }
#define neen(m, n) if ((m) != (n)) { DK_LOG_ERROR_ERRNO(); }

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

#define nullsc(n) nulleqen((n))

#endif // common_hxx
