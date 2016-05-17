# include <dlfcn.h> // dlopen()/dlclose()

# include "pathname-for-handle.hh"

# define cast(t) (t)

# if defined __linux__
# if ! defined _GNU_SOURCE
# define _GNU_SOURCE // dlinfo()
# endif
# include <link.h>

auto pathname_for_handle(void* handle) -> const char* {
  if (nullptr == handle)
    return nullptr;
  struct link_map* l_map = nullptr;
  int e = dlinfo(handle, RTLD_DI_LINKMAP, &l_map);
  if (-1 != e && nullptr != l_map->l_name)
    return l_map->l_name;
  return nullptr;
}
# elif defined __APPLE__
# include <stdint.h>
# include <mach-o/dyld.h>
# include <mach-o/nlist.h>

auto pathname_for_handle(void* handle) -> const char* {
  if (nullptr == handle)
    return nullptr;
  for (int32_t i = cast(int32_t)_dyld_image_count(); i >= 0 ; i--) {
    const char* image_name = _dyld_get_image_name(cast(uint32_t)i);
    void* image_handle = dlopen(image_name, RTLD_NOLOAD);
    dlclose(image_handle);

    if (handle == image_handle)
      return image_name;
  }
  return nullptr;
}
# endif
