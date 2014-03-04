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

#if !defined(__sys_h__)
#define __sys_h__

#include <getopt.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <stdio.h>
#include <sys/time.h>
#include <sys/signal.h>
#define __USE_POSIX 1
#include <time.h>

#if HAVE_KQUEUE
#include <sys/event.h>
#endif

#ifndef __STDC_FORMAT_MACROS
#define __STDC_FORMAT_MACROS
#endif //__STDC_FORMAT_MACROS
#include <inttypes.h>

#include "sys-epoll.h"

#if HAVE_POLL
#include <sys/poll.h>
#endif

#include "common.h"

#define __format_printf(fmtarg) \
		__attribute__((__format__ (__printf__, fmtarg, fmtarg + 1)))

#define __format_scanf(fmtarg) \
		__attribute__((__format__ (__scanf__, fmtarg, fmtarg + 1)))

extern const char8_t* __progname;

namespace sys
{
  int_t pipe(int_t fds[2]);
  int_t     close(int_t fd);
  void*   malloc(size_t size);
  void    free(void* ptr);
  ssize_t read(int_t fd, void* buf, size_t len);
  ssize_t recvfrom(int_t fd, void* buf, size_t len, int_t flags, struct sockaddr* sa, socklen_t* salen);
  ssize_t write(int_t fd, const void* buf, size_t len);
  ssize_t sendto(int_t fd, const void* buf, size_t len, int_t flags, const struct sockaddr* sa, socklen_t salen);
  pid_t   fork();
  int_t socket(int_t domain, int_t type, int_t protocol);
  int_t connect(int_t fd, const struct sockaddr* name, socklen_t namelen);
  int_t accept(int_t fd, struct sockaddr* addr, socklen_t* addrlen);
  int_t listen(int_t fd, int_t backlog);
  int_t getsockopt(int_t fd, int_t level, int_t optname, void* optval, socklen_t* optlen);
  int_t setsockopt(int_t fd, int_t level, int_t optname, const void* optval, socklen_t optlen);
  int_t bind(int_t fd, const struct sockaddr* name, socklen_t namelen);
  int_t fcntl(int_t fd, int_t cmd, int_t arg);
  int_t dup2(int_t fd, int_t newfd);
  const char8_t* inet_ntop(int_t af, const void* src, char8_t* dst, socklen_t size);
  int_t inet_pton(int_t af, const char8_t* src, void* dst);
#if HAVE_KQUEUE
  int_t kqueue();
  int_t kevent(int_t kq,
             const struct kevent* changelist, int_t nchanges,
             struct kevent* eventlist, int_t nevents,
             const struct timespec* timeout);
#else
#if HAVE_EPOLL || HAVE_POLL
  int_t epoll_create(int_t size);
  int_t epoll_ctl(int_t epfd, int_t op, int_t fd, struct epoll_event* event);
  int_t epoll_wait(int_t epfd, struct epoll_event* events, int_t maxevents, int_t timeout);
#endif
#endif
#if HAVE_POLL && USE_POLL
  int_t poll(pollfd* pfds, nfds_t nfds, int_t timeout);
#endif
  int_t sigaction(int_t sig,
                const struct sigaction* act,
                struct sigaction* oact);
  int_t sigpending(sigset_t* set);
  int_t sigsuspend(const sigset_t* sigmask);
  int_t sigprocmask(int_t how, const sigset_t* set, sigset_t* oset);
  char8_t* getenv(const char8_t* name);
  intmax_t strtoimax(const char8_t* nptr, char8_t** endptr, int_t base);
  uintmax_t strtoumax(const char8_t* nptr, char8_t** endptr, int_t base);
  pid_t getpid();
  FILE* fopen(const char8_t* path, const char8_t* mode);
  int_t fflush(FILE* file);
  int_t fclose(FILE* file);
  int_t fprintf(FILE* stream, const char8_t* format, ...) __format_printf(2);
  int_t snprintf(char8_t* str, size_t size, const char8_t* format, ...) __format_printf(3);
  int_t vfprintf(FILE* stream, const char8_t* format, va_list_t ap);
  int_t vsnprintf(char8_t* str, size_t size, const char8_t* format, va_list_t ap);
  struct tm* localtime_r(const time_t* timep, struct tm* result);
  void abort();
  pid_t waitpid(pid_t wpid, int* status, int_t options);
  void exit(int_t status);
  int_t stat(const char8_t* path, struct stat* buf);
  int_t fstat(int_t filedes, struct stat* buf);
  int_t getsockname(int_t s, struct sockaddr* name, socklen_t* namelen);
  int_t getpeername(int_t s, struct sockaddr* name, socklen_t* namelen);
  int_t chdir(const char8_t* path);
  char8_t* getcwd(char8_t* buf, size_t size);

  FILE* fopen(const char8_t* path, const char8_t* mode);
  char8_t* getenv(const char8_t* name);
  char8_t* strcat(char8_t* dest, const char8_t* src);
  char8_t* strchr(const char8_t* s, int_t c);
  char8_t* strcpy(char8_t* dest, const char8_t* src);
  char8_t* strerror(int_t errnum);
  char8_t* strncpy(char8_t* dest, const char8_t* src, size_t n);
  char8_t* strrchr(const char8_t* s, int_t c);
  char8_t* strsep(char8_t** stringp, const char8_t* delim);
  int_t execve(const char8_t* filename, char8_t* const argv [], char8_t* const envp[]);
  int_t fprintf(FILE* stream, const char8_t* format, ...);
  int_t gettimeofday(struct timeval* tv, struct timezone* tz);
  int_t setsockopt(int_t s, int_t level, int_t optname, const void* optval, socklen_t optlen);
#undef sigemptyset // darwin hackhack
  int_t sigemptyset(sigset_t* set);
#undef sigfillset // darwin hackhack
  int_t sigfillset(sigset_t* set);
  int_t sigprocmask(int_t how, const sigset_t* set, sigset_t* oldset);
  int_t snprintf(char8_t* str, size_t size, const char8_t* format, ...);
  char8_t* strerror_r(int_t errnum, char8_t* buf, size_t n);
  int_t vfprintf(FILE* stream, const char8_t* format, va_list_t ap);
  intmax_t strtoimax (const char8_t* nptr, char8_t** endptr, int_t base);
  pid_t getpid(void);
  size_t strftime(char8_t* s, size_t max, const char8_t* format, const struct tm* tm);
  struct tm* localtime_r(const time_t* timep, struct tm* result);
#undef htons // darwin hackhack
  uint16_t htons(uint16_t hostshort);
#undef ntohs // darwin hackhack
  uint16_t ntohs(uint16_t netshort);
#undef htonl // darwin hackhack
  uint32_t htonl(uint32_t hostlong);
#undef ntohl // darwin hackhack
  uint32_t ntohl(uint32_t netlong);
  uintmax_t strtoumax (const char8_t* nptr, char8_t** endptr, int_t base);
  void* malloc(size_t size);
  void* memcpy(void* dest, const void* src, size_t n);
  void* memmove(void* dest, const void* src, size_t n);
#undef memset
  void* memset(void* s, int_t c, size_t n);
  void exit(int_t status);
  void free(void* ptr);
  int_t daemon(int_t nochdir, int_t noclose);
  int_t setpriority(int_t which, int_t who, int_t prio);
  void* dlopen(const char8_t* filename, int_t flag);
  char8_t* dlerror(void);
  void* dlsym(void* handle, const char8_t* symbol);
  int_t dlclose(void* handle);
  int_t getopt_long(int_t argc, char8_t*  const argv[], const char8_t* optstring, const struct option* longopts, int_t* longindex);

  const char8_t* getprogname(void);
  void setprogname(const char8_t* progname);
}

#endif
