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

#if !defined(__common_h__)
#define __common_h__

#include <sys/cdefs.h>
#include <netinet/in.h>

#include "config.h"

#define slots_typedef(a, b)  namespace a { typedef b slots_t; } typedef a::slots_t a ## _t

slots_typedef(xin4_addr, in_addr); // struct
slots_typedef(in_port, in_port_t);
slots_typedef(xsockaddr_in4, sockaddr_in); // struct
slots_typedef(boole, bool);
slots_typedef(fd, int_t);

#include "log.h"
#include "sys.h"

#ifdef __unused
#undef __unused
#endif
#define __unused __attribute__((__unused__))

#define __format_printf(fmtarg) \
		__attribute__((__format__ (__printf__, fmtarg, fmtarg + 1)))

#define __format_scanf(fmtarg) \
		__attribute__((__format__ (__scanf__, fmtarg, fmtarg + 1)))

extern const xin4_addr_t RECRUITER_ADDR;
extern const in_port_t RECRUITER_PORT;

extern const xin4_addr_t RECRUITER_LOOPBACK_ADDR;
extern const in_port_t RECRUITER_LOOPBACK_PORT;

extern const xin4_addr_t GROUP_ADDR;
extern const in_port_t GROUP_PORT;

#define SUPPORT_STDIN_PIPE 1

#endif
