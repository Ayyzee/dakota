#include "set-read-only.hh"

int main() {
  dk_intern(symbol_addrs, symbol_strs, symbol_len);
#if 1
  set_read_only("__dk_readonly");
#endif
  __symbol::_first = ""; // causes SIGBUS or SIGSEGV
  return 0;
}
