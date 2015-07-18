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

static void
handler(int sig, siginfo_t *si, void *unused) {
  printf("caught sig%s at %p\n",
         sys_signame[sig], si->si_addr);
  exit(EXIT_FAILURE);
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
    e = sigaction(sig,  &sa, NULL); if (-1 == e) handle_error("sigaction");
  }
  __symbol::_first = ""; // causes SIGBUS or SIGSEGV
  return 0;
}
