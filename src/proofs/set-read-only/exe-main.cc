# include <errno.h>
# include <signal.h>
# include <stdarg.h>
# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <sys/mman.h>
# include <syslog.h>
# include <unistd.h>

# include "set-read-only.hh"

# define handle_error(msg) \
  do { perror(msg); exit(EXIT_FAILURE); } while (0)

static char8_t const* progname;

typedef void (*sa_handler_t)(int_t, siginfo_t*, void*);
typedef struct sigaction sigaction_t;

struct sa_pair_t {
  sa_handler_t handler;
  sigaction_t  prev_sa;
};
static int8_t const index_from_sig[NSIG] = {
  [SIGBUS] =  0,
  [SIGSEGV] = 1,
};
static sa_pair_t sa_pairs[] = {
  { .handler = nullptr, .prev_sa = {} },
  { .handler = nullptr, .prev_sa = {} },
};

static void
bus_segv_handler(int_t sig, siginfo_t *si, void *unused) {
  syslog(LOG_ERR, "caught sig%s at %p\n",
         sys_signame[sig], si->si_addr);
  sa_handler_t prev_sa_handler = sa_pairs[index_from_sig[sig]].prev_sa.sa_sigaction;

  if (prev_sa_handler &&
      prev_sa_handler != cast(sa_handler_t)SIG_DFL &&
      prev_sa_handler != cast(sa_handler_t)SIG_IGN) {
    prev_sa_handler(sig, si, unused);
  }
  return;
}
static int_t
sigaction_setup(int_t sig, sa_handler_t bus_segv_handler) {
  int_t r = -1;
  sigaction_t sa {};
  sa.sa_flags = SA_SIGINFO | SA_RESETHAND;
  sigemptyset(&sa.sa_mask);
  sa.sa_sigaction = bus_segv_handler;
  
  sa_pairs[index_from_sig[sig]].prev_sa.sa_sigaction = nullptr;
  r = sigaction(sig,  &sa, &sa_pairs[index_from_sig[sig]].prev_sa);
  if (-1 == r) handle_error("sigaction");
  return r;
}

int_t
main(int_t, char8_t const* const argv[]) {
  progname = argv[0];
  dk_intern(symbol_addrs, symbol_strs, symbol_len);
# if 1
  set_read_only("__DKT_RODATA");
# endif
  openlog(progname, LOG_CONS | LOG_PID | LOG_PERROR, LOG_USER);
  sigaction_setup(SIGBUS,  bus_segv_handler);
  sigaction_setup(SIGSEGV, bus_segv_handler);
  __symbol::_first = ""; // causes SIGBUS or SIGSEGV
  return 0;
}
