// mprotect()
#include <sys/types.h>
#include <sys/mman.h>

// getpagesize()
#include <unistd.h>

// sigaction()
#include <signal.h>

// fprintf()
#include <stdio.h>

#define _XOPEN_SOURCE 600
#include <stdlib.h>

#include "sc.h"

struct pg_t
{
     void* addr;
     size_t size;
};

static pg_t pg[1] = {{0, 0}}; // hackhack

// keep info for mprotect()
static void pg_add_size_for_addr(void* addr, size_t size)
{
     pg[0].addr = addr; // hackhack
     pg[0].size = size; // hackhack
     return;
}

static size_t pg_size_for_addr(void* addr)
{
     size_t size = 0;
     for (size_t i = 0; i < sizeof(pg)/sizeof(pg[0]); i++)
     {
          if (addr == pg[i].addr)
               size = pg[i].size;
     }
     return size;
}

static void pg_read_sigaction(int s, siginfo_t* si, void* p)
{
     fprintf(stderr, "%s(%i, %p, %p)\n", __func__, s, si, p);
     // should just add read
     int result = mprotect(si->si_addr, pg_size_for_addr(si->si_addr), PROT_READ);  sc(result);
     fprintf(stderr, "%i = mprotect(%p, %zi, %i)\n", result, si->si_addr, pg_size_for_addr(si->si_addr), PROT_READ);
     return;
}

static void pg_write_sigaction(int s, siginfo_t* si, void* p)
{
     fprintf(stderr, "%s(%i, %p, %p)\n", __func__, s, si, p);
     // should just add write
     int result = mprotect(si->si_addr, pg_size_for_addr(si->si_addr), PROT_WRITE);  sc(result);
     fprintf(stderr, "%i = mprotect(%p, %zi, %i)\n", result, si->si_addr, pg_size_for_addr(si->si_addr), PROT_WRITE);
     return;
}

// page malloc
void* pg_malloc(size_t size)
{
#if HAVE_POSIX_MEMALIGN
     void* addr;
     int n = posix_memalign(&addr, getpagesize(), size); sc(n);
#else
     size_t num_pages = 1;
     if (size > (size_t)getpagesize()) // normally size is going to be sizeof(void*)
       num_pages += size/getpagesize();
     void* addr = mmap(NULL, num_pages, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0); sc((int)addr);
#endif

     pg_add_size_for_addr(addr, size);
     return addr;
}

void pg_guard_read(void* addr)
{
     int result;
     struct sigaction sa;
     sa.sa_sigaction = pg_read_sigaction;
     sa.sa_flags = SA_SIGINFO;
     sigemptyset(&sa.sa_mask);

     result = sigaction(SIGBUS, &sa, NULL);  sc(result);

     // should just remove read
     result = mprotect(addr, pg_size_for_addr(addr), PROT_NONE);  sc(result);
     fprintf(stderr, "%i = mprotect(%p, %zi, %i)\n", result, addr, pg_size_for_addr(addr), PROT_NONE);

     return;
}

void pg_guard_write(void* addr)
{
     int result;
     struct sigaction sa;
     sa.sa_sigaction = pg_write_sigaction;
     sa.sa_flags = SA_SIGINFO;
     sigemptyset(&sa.sa_mask);

     result = sigaction(SIGBUS, &sa, NULL);  sc(result);

     // should just remove write
     result = mprotect(addr, pg_size_for_addr(addr), PROT_NONE);  sc(result);
     fprintf(stderr, "%i = mprotect(%p, %zi, %i)\n", result, addr, pg_size_for_addr(addr), PROT_NONE);

     return;
}
