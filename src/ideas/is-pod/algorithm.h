namespace __gnu_internal
{
  typedef char __one;
  typedef char __two[2];

  template<typename _Tp> __one  __test_type(int _Tp::*);
  template<typename _Tp> __two& __test_type(...);
}

namespace std
{
  template<typename _Tp> struct __is_pod
  {
    enum
      {
	__value = (sizeof(__gnu_internal::__test_type<_Tp>(0)) != sizeof(__gnu_internal::__one))
      };
  };
}
