# include <mach-o/ldsyms.h>

# include "set-read-only.hh"

namespace __symbol {
  page_align
  symbols_section symbol_t _first;
  // ...
  symbols_section symbol_t _last;
}
symbol_t* const symbol_addrs[] = { // read-write
  &__symbol::_first,
  // ...
  &__symbol::_last,
};
char const* const symbol_strs[] = { // read-only
  "first",
  // ...
  "last",
};
size_t symbol_len = COUNTOF(symbol_addrs);

static_assert(COUNTOF(symbol_addrs) == COUNTOF(symbol_strs), "symbol_addrs and symbol_strs must be same len");
symbol_t dk_intern(char const* str) {
  return str;
}
void dk_intern(symbol_t* const addrs[], char const* const strs[], size_t len) {
  for (unsigned int i = 0; i < len; i++) {
    *(addrs[i]) = dk_intern(strs[i]);
  }
  return;
}
// darwin: getsegmentata() and mprotect()
// linux:  elf_getdata()   and mprotect()

extern void* __dso_handle;
static void* get_segment_data(char8_t const* segment, void** addrout, ulint_t* sizeout) {
  // darwin
  *addrout = cast(void*)getsegmentdata(cast(const struct mach_header_64*)&__dso_handle, segment, sizeout);

// #include <libelf.h>

//   Elf_Data *elf_getdata(Elf_Scn *scn, Elf_Data *data);

  // linux
  // ...
  return *addrout;
}

int_t
set_read_only(char8_t const* segment) {
  assert(NULL != segment);
  // long pagesize = sysconf(_SC_PAGESIZE);
  // assert(__pagesize == pagesize);

  void* addr = nullptr;
  size_t size = 0;
  get_segment_data(segment, &addr, &size); // linux & darwin version
  printf("%p\n", addr);
  int_t result = -1;

  if (NULL != addr) {
    result = mprotect(addr, size, PROT_READ);
  }
  if (0 != result) {
    fprintf(stderr, "%s() failed\n", __func__);
  }
  return result;
}
