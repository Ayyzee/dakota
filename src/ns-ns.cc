# include <cstdio>

# define func auto

namespace __signature { namespace va {
} }
namespace object {
  //namespace __signature { using namespace ::__signature; }
  namespace __signature { namespace va { using namespace ::__signature::va; } }
  namespace __signature {
    namespace va { static const char* foo = "object::__signature::va::foo"; }
  }
}
namespace __signature {
  namespace va { static const char* foo = "__signature::va::foo"; } // never used
  namespace va { static const char* bar = "__signature::va::bar"; }
}
namespace object {
  namespace va { static func foo(void*, va_list) -> void {
    static const char* sig = __signature::va::foo;
    printf("%p: %s\n", sig, sig);
  } }
  namespace va { static func bar(void*, va_list) -> void {
    static const char* sig = __signature::va::bar;
    printf("%p: %s\n", sig, sig);
  } }
}
// namespace object {
//   static func foo(void*, ...) -> void {
//     static const char* sig = __signature::foo;
//     printf("%p: %s\n", sig, __PRETTY_FUNCTION__);
//   }
//   static func bar(void*, ...) -> void {
//     static const char* sig = __signature::bar;
//     printf("%p: %s\n", sig, __PRETTY_FUNCTION__);
//   }
// }

func main() -> int {
  printf("%p: %s\n",         __signature::va::foo,         __signature::va::foo);
  printf("%p: %s\n",         __signature::va::bar,         __signature::va::bar);
  printf("%p: %s\n", object::__signature::va::foo, object::__signature::va::foo);
  printf("\n");

  object::va::foo(nullptr, nullptr);
  object::va::bar(nullptr, nullptr);
  return 0;
}
// clang++ -std=c++11 --warn-everything --warn-no-old-style-cast --warn-no-c++98-compat --output ns-ns ns-ns.cc && ./ns-ns
