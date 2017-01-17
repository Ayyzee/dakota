// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# pragma once

# define HAVE_EPOLL 1
# define HAVE_POLL 1
# define HAVE_PROCFS 1

# define USE_POLL 1
# define USE_DLADDR 1
# define USE_SYSLOG 0
# define USE_SYS 1

__BEGIN_DECLS
# ifndef HAVE_GETPROGNAME
# ifdef HAVE_PROCFS
FUNC getprogname() -> const char_t*;
# endif // HAVE_PROCFS
# endif // HAVE_GETPROGNAME
__END_DECLS

static str_t so_ext = "so";
