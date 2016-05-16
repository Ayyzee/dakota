# if ! defined _GNU_SOURCE
# define _GNU_SOURCE // dlinfo()
# endif
# include <link.h>
# include <dlfcn.h>  // dlopen()/dlclose()

# include "pathname-for-handle.hh"

auto pathname_for_handle(void* handle) -> const char* {
  struct link_map* l_map = nullptr;
  int e = dlinfo(handle, RTLD_DI_LINKMAP, &l_map);
  if (-1 != e && nullptr != l_map->l_name)
    return l_map->l_name;
  return nullptr;
}
