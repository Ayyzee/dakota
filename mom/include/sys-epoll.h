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

#if !defined(__sys_epoll_h__)
#define __sys_epoll_h__

#include "config.h"

#if HAVE_EPOLL
#include <sys/epoll.h>
#else
#if HAVE_POLL && USE_POLL
#include <stdint.h>

enum EPOLL_EVENTS
{
  EPOLLIN =     (1 <<  0), // 0x001
  EPOLLPRI =    (1 <<  1), // 0x002
  EPOLLOUT =    (1 <<  2), // 0x004
  EPOLLERR =    (1 <<  3), // 0x008
  EPOLLHUP =    (1 <<  4), // 0x010

  //POLLNVAL =  (1 <<  5), // in sys/poll.h

  EPOLLRDNORM = (1 <<  6), // 0x040
  EPOLLRDBAND = (1 <<  7), // 0x080
  EPOLLWRNORM = (1 <<  8), // 0x100
  EPOLLWRBAND = (1 <<  9), // 0x200
  //EPOLLMSG =  (1 << 10), // not supported in nepoll
  
  //EPOLLET =   (1 << 31), // not supported in nepoll
};

enum
{
  EPOLL_CTL_ADD = 1,
  EPOLL_CTL_DEL = 2,
  EPOLL_CTL_MOD = 3,
};

typedef union epoll_data
{
  void* ptr;
  int fd;
  uint32_t u32;
  uint64_t u64;
} epoll_data_t;

struct epoll_event
{
  uint32_t events;
  epoll_data_t data;
};
#endif
#endif
#endif
