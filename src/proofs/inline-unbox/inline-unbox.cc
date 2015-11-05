# define cast(t) (t)

// static seems to imply inline in this example
# if defined should_inline
  # define unbox_attrs inline __attribute__((__always_inline__,__pure__,__nothrow__,__hot__))
# else
  # define unbox_attrs 
# endif

namespace object { struct slots_t; }
typedef object::slots_t* object_t;
namespace object
{
  struct slots_t { object_t klass; };
  object_t klass;
}
namespace klass
{
  struct slots_t { void*        methods;
                   unsigned int offset; };
  object_t klass;

  unbox_attrs slots_t* unbox(object_t object) // special_case
  {
    return cast(slots_t*)(cast(unsigned char*)object + sizeof(object::slots_t));
  }
}
namespace point
{
  struct slots_t { int x; int y; };
  object_t klass; // instace of klass 'klass'

  unbox_attrs slots_t* unbox(object_t object) // general case
  {
    //if (0 == object) return (slots_t*)0; else return cast(slots_t*)(cast(unsigned char*)object + klass::unbox(klass)->offset);
    //return 0 == object ? (slots_t*)0 : cast(slots_t*)(cast(unsigned char*)object + klass::unbox(klass)->offset);
    return cast(slots_t*)(cast(unsigned char*)object + klass::unbox(klass)->offset);
  }
  object_t set(object_t self, int x, int y)
  {
    unbox(self)->x = x;
    unbox(self)->y = y;
    return self;
  }
}
