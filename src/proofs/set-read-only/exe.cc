#include <unistd.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>

#include "set-read-only.hh"

#define handle_error(msg) \
  do { perror(msg); exit(EXIT_FAILURE); } while (0)

static struct sigaction prev_sa[NSIG];

static void
handler(int sig, siginfo_t *si, void *unused) {
  printf("caught sig%s at %p\n",
         sys_signame[sig], si->si_addr);
  if (nullptr == prev_sa[sig].sa_sigaction) {
    exit(EXIT_FAILURE);
  } else {
    prev_sa[sig].sa_sigaction(sig, si, unused);
  }
  return;
}

int
main() {
  dk_intern(symbol_addrs, symbol_strs, symbol_len);
#if 1
  set_read_only("__DK_RODATA");
#endif
  int e;
  struct sigaction sa {};

  sa.sa_flags = SA_SIGINFO;
  sigemptyset(&sa.sa_mask);
  sa.sa_sigaction = handler;
  
  //for (int sig in { x, y })
  //
  //for ( ?type ?ident in { ?block-in } )
  //=>
  //for ( ?type ?ident : ( ?type [] ) { ?block-in } )

  for (int sig : (int []){ SIGBUS, SIGSEGV }) {
    prev_sa[sig].sa_sigaction = nullptr;
    e = sigaction(sig,  &sa, &prev_sa[sig]); if (-1 == e) handle_error("sigaction");
  }
  __symbol::_first = ""; // causes SIGBUS or SIGSEGV
  return 0;
}
