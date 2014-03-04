#if !defined __sys_event_h__
#define __sys_event_h__

#include <stdint.h>

#define EVFILT_READ             (-1)
#define EVFILT_WRITE            (-2)
#define EVFILT_SIGNAL           (-6)

struct kevent
{
  uintptr_t          ident;
  short int          filter;
  unsigned short int flags;
  unsigned int       fflags;
  intptr_t           data;
  void*              udata;
};

#define EV_SET(kevp, a, b, c, d, e, f) do {     \
        struct kevent *__kevp__ = (kevp);       \
        __kevp__->ident = (a);                  \
        __kevp__->filter = (b);                 \
        __kevp__->flags = (c);                  \
        __kevp__->fflags = (d);                 \
        __kevp__->data = (e);                   \
        __kevp__->udata = (f);                  \
} while(0)

// actions
#define EV_ADD          0x0001          // add event to kq (implies enable)
#define EV_DELETE       0x0002          // delete event from kq

// flags
#define EV_ONESHOT      0x0010          // only report one occurrence

// returned values
#define EV_EOF          0x8000          // EOF detected
#define EV_ERROR        0x4000          // error, data contains errno

struct timespec;

__BEGIN_DECLS
int
kqueue(void);

int
kevent(int kq,
       const struct kevent* changelist, int nchanges,
       struct kevent* eventlist, int nevents,
       const struct timespec* timeout);
__END_DECLS
#endif // !__sys_event_h__
