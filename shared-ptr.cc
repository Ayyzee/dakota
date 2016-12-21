// -*- mode: c++ -*-

// http://stackoverflow.com/questions/9200664/how-is-the-stdtr1shared-ptr-implemented

# include <chrono>
# include <iostream>
# include <memory>
# include <mutex>
# include <thread>

template<typename T> struct shared_ptr {
  struct aux {
    unsigned count;
    aux() : count(1) {}
    virtual ~aux() {} // must be polymorphic
    virtual auto destroy() -> void = 0;
  };
  template<typename U, typename Deleter> struct auximpl : public aux {
    U*      p;
    Deleter d;
    auximpl(U* pu, Deleter x) : p(pu), d(x) {}
    virtual auto destroy() -> void { d(p); } 
  };
  template<typename U> struct default_deleter { auto operator()(U* p) const -> void { delete p; } };
  aux* pa;
  T*   pt;
  // object_t klass;
  // boole_t is_weak;
  auto inc() -> void { if (pa) interloked_inc(pa->count); }
  auto dec() -> void { 
    if (pa && !interlocked_dec(pa->count)) {
      pa->destroy();
      delete pa;
    }
  }
  shared_ptr(const shared_ptr& s) : pa(s.pa), pt(s.pt) { inc(); }
  shared_ptr() : pa(), pt() {}
  ~shared_ptr() { dec(); }
  template<typename U, typename Deleter> shared_ptr(U* pu, Deleter d) : pa(new auximpl<U,Deleter>(pu, d)), pt(pu) {}
  template<typename U> explicit shared_ptr(U* pu) : pa(new auximpl<U, default_deleter<U> >(pu, default_deleter<U>())), pt(pu) {}
  template<typename U> shared_ptr(const shared_ptr<U>& s) : pa(s.pa), pt(s.pt) { inc(); }
  auto operator=(const shared_ptr& s) -> shared_ptr& {
    if (this != &s) {
      dec();
      pa = s.pa;
      pt = s.pt;
      inc();
    }
    return *this;
  }
  auto operator->() const -> T* { return  pt; }
  auto operator*()  const -> T& { return *pt; }
};
auto main() -> int {
  return 0;
}
// shared_ptr must manage a reference counter and the carrying of a deleter functor
// that is deduced by the type of the object given at initialization.

// The shared_ptr class typically hosts two members: a T* (that is returned by operator->
// and dereferenced in operator*) and a aux* where aux is a inner abstract class that contains:

//   - a counter (incremented / decremented upon copy-assign / destroy)
//   - what needed to make increment / decrement atomic (not needed is
//     specific platform atomic INC/DEC are available)
//   - an abstract virtual destroy() = 0;
//   - a virtual destructor.

// such aux class (the actual name depends on the implementation) is derived by a family of templatized
// classes (parametrized on the type given by the explicit constructor, say U derived from  T), that add:

//   - a pointer to the object (same as T*, but with the actual type:
//     this is needed to properly manage all the cases of T being a base
//     for whatever U having multiple T in the derivation hierarchy)
//   - a copy of the deletor object given as deletion policy to the
//     explicit constructor (or the default deletor just doing delete p,
//     where p is the U* above)
//   - the override of the destroy method, calling the deleter functor.

// clang++ -std=c++14 --warn-everything --warn-no-c++98-compat --warn-no-old-style-cast --output shared-ptr shared-ptr.cc
