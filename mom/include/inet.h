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

#if !defined(__inet_h__)
#define __inet_h__

#include <sys/types.h>
#include <errno.h>  // errno
#include <string.h> // strerror()
#include <stdio.h>  // fprintf()
#include <sys/socket.h> // struct sockaddr_in
#include <netinet/in.h>
#include <stdint.h>

#include "hacks.h"

import xin4_addr_t xin4_addr_create(uint8_t a, uint8_t b, uint8_t c, uint8_t d);
noexport const char8_t* strsocktype(int_t socktype);
import xsockaddr_in4_t xsockaddr_in4_create(xin4_addr_t addr, in_port_t port);
noexport xin4_addr_t sin4_addr_ntoh(xin4_addr_t sin_addr);
noexport xin4_addr_t sin4_addr_hton(xin4_addr_t sin_addr);
noexport xsockaddr_in4_t* sin4_ntoh(xsockaddr_in4_t* sin);
noexport xsockaddr_in4_t* sin4_hton(xsockaddr_in4_t* sin);
noexport xsockaddr_in4_t sin4_statestr(xsockaddr_in4_t sin, char8_t* buf, size_t buflen);
import int_t in4_getsockname(fd_t fd, xsockaddr_in4_t* sin);
noexport int_t in4_getpeername(fd_t fd, xsockaddr_in4_t* sin);
import const char8_t* in4_ntop(xin4_addr_t addr, char8_t* dst, socklen_t dstlen);
noexport int32_t in4_bind(fd_t fd, xsockaddr_in4_t sin);
noexport int32_t in_listen(fd_t fd, int32_t backlog);
noexport int32_t in4_connect(fd_t fd, xsockaddr_in4_t sin);
noexport fd_t in4_accept(fd_t fd, xsockaddr_in4_t* sin);
noexport ssize_t in4_recvfrom(fd_t fd, void* buf, size_t len, int_t flags, xsockaddr_in4_t* sin);
noexport fd_t in4_stream_socket();
noexport fd_t ucast_client(xsockaddr_in4_t sin);
import fd_t ucast_server(xsockaddr_in4_t sin, int32_t backlog);
noexport fd_t in4_dgram_socket();
noexport fd_t mcast_client(xsockaddr_in4_t sin);
import fd_t mcast_server(xsockaddr_in4_t sin);
noexport ip_mreq membership_request(xin4_addr_t addr);
import int32_t mcast_server_join_group(fd_t fd, xin4_addr_t addr);
import int32_t mcast_server_leave_group(fd_t fd, xin4_addr_t addr);
import xsockaddr_in4_t sin4_dump(xsockaddr_in4_t sin, const char8_t* file, int_t line);

// this should be done with the macro system
#define sin4_dump(sin) sin4_dump(sin, __FILE__, __LINE__)
#endif
