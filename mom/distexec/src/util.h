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

#if !defined(__util_h__)
#define __util_h__

#include <getopt.h>

#include "inet.h"

char8_t* // NULL on error
resolve_path(char8_t* path, size_t pathlen, const char8_t* file);

int32_t
int32_from_string(const char8_t* str, int32_t default_int32);

uint32_t
uint32_from_string(const char8_t* str, uint32_t default_uint32);

in_port_t
port_from_string(const char8_t* port_str, in_port_t default_port);

in_port_t
port_from_hex_string(const char8_t* port_str, in_port_t default_port);

in_port_t
port_getenv(const char8_t* key, in_port_t default_port);

xin4_addr_t
addr_from_string(const char8_t* addr_str, xin4_addr_t default_addr);

xin4_addr_t
addr_getenv(const char8_t* key, xin4_addr_t default_addr);

xsockaddr_in4_t* // NULL on error
string_to_sockaddr(const char8_t* str, sockaddr_in* sinp);

int32_t
int32_getenv(const char8_t* key, int32_t default_int32);

uint32_t
uint32_getenv(const char8_t* key, uint32_t default_uint32);

char8_t* // NULL on error
port_to_string(in_port_t port, char8_t* buf, size_t buflen);

char8_t* // NULL on error
addr_to_string(xin4_addr_t addr, char8_t* buf, size_t buflen);

#endif
