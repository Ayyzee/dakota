typedef void* object_t;
typedef object_t (*method_t)(object_t);
typedef int int_t;

namespace __exported_method
{
  static inline method_t* bar(object_t, int_t)
  {
    static method_t m;
    return &m;
  }
}

namespace foo
{
  static inline object_t bar(object_t self, int_t i)
  {
    object_t (**m)(object_t, int_t) = (object_t (**)(object_t, int_t))__exported_method::bar(self, i);
    object_t r = (*m)(self, i);
    return r;
  }
}

void dummy()
{
  object_t o;
  int_t i;
  foo::bar(o, i);
}
