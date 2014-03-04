#include <stdint.h>

enum EPOLL_EVENTS
  {
    EPOLLIN = 0x001,
#define EPOLLIN EPOLLIN
    EPOLLPRI = 0x002,
#define EPOLLPRI EPOLLPRI
    EPOLLOUT = 0x004,
#define EPOLLOUT EPOLLOUT
    EPOLLRDNORM = 0x040,
#define EPOLLRDNORM EPOLLRDNORM
    EPOLLRDBAND = 0x080,
#define EPOLLRDBAND EPOLLRDBAND
    EPOLLWRNORM = 0x100,
#define EPOLLWRNORM EPOLLWRNORM
    EPOLLWRBAND = 0x200,
#define EPOLLWRBAND EPOLLWRBAND
    EPOLLMSG = 0x400,
#define EPOLLMSG EPOLLMSG
    EPOLLERR = 0x008,
#define EPOLLERR EPOLLERR
    EPOLLHUP = 0x010,
#define EPOLLHUP EPOLLHUP
    EPOLLONESHOT = (1 << 30),
#define EPOLLONESHOT EPOLLONESHOT
    EPOLLET = (1 << 31)
#define EPOLLET EPOLLET
  };


  /* Valid opcodes ( "op" parameter ) to issue to epoll_ctl().  */
#define EPOLL_CTL_ADD 1/* Add a file decriptor to the interface.  */
#define EPOLL_CTL_DEL 2/* Remove a file decriptor from the interface.  */
#define EPOLL_CTL_MOD 3/* Change file decriptor epoll_event structure.  */

union epoll_data
{
  void *ptr;
  int fd;
  uint32_t u32;
  uint64_t u64;
};
typedef union epoll_data epoll_data_t;

struct epoll_event
{
  uint32_t events;
  epoll_data_t data;
};
typedef struct epoll_event epoll_event_t;

int
epoll_create(int size);

int
epoll_ctl(int epfd, int op, int fd, epoll_event_t* event);

int
epoll_wait(int epfd, epoll_event_t* events, int num_events, int timeout);
