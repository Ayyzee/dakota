// object
namespace object { struct slots_t; }
typedef   object::slots_t* object_t;
namespace object { struct slots_t { object_t klass; }; }
namespace object { extern object_t klass; }
namespace object { object_t klass; }

namespace object { slots_t* unbox(object_t object); } // Koenig lookup does not allow this???
namespace object { slots_t* unbox(object_t object)    // Koenig lookup does not allow this???
{
  return object;
}}

// klass
namespace klass { struct slots_t; }
namespace klass { struct slots_t { void* methods; unsigned int methods_len; unsigned int offset; }; }
namespace klass { extern object_t klass; }
namespace klass { object_t klass; }

namespace klass { slots_t* unbox(object_t object); }
namespace klass { slots_t* unbox(object_t object)
{
  slots_t* s = 0;
  if (0 != object)
    s = (slots_t*)((unsigned char*)object + sizeof(object::slots_t));
  return s;
}}

// string
namespace string { struct slots_t; }
namespace string { struct slots_t { const char* cstr; unsigned int cstr_len; }; }
namespace string { extern object_t klass; }
namespace string { object_t klass; }

namespace string { slots_t* unbox(object_t object); }
namespace string { slots_t* unbox(object_t object)
{
  slots_t* s = 0;
  if (0 != object)
    s = (slots_t*)((unsigned char*)object + klass::unbox(klass)->offset);
  return s;
}}

int main()
{
  return 0;
}
