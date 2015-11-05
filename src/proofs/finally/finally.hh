// http://www.codeproject.com/Tips/476970/finally-clause-in-Cplusplus

# if !defined(__FINALLY_HH__)
# define __FINALLY_HH__
# include <functional>

class finally
{
  std::function<void(void)> functor;
public:
  finally(const std::function<void(void)> &functor) : functor(functor) {}
  ~finally() { functor(); }
};
# endif
