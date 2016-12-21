// -*- mode: c++ -*-

// http://stackoverflow.com/questions/9200664/how-is-the-stdtr1shared-ptr-implemented

// # include <memory>
// # include <mutex>
// # include <thread>

# include <cstdio>
# include <cstdint>

inline auto interlock_incr(int64_t* i) -> int64_t {
  return __sync_add_and_fetch(i, 1); // gcc/clang specific
}
inline auto interlock_decr(int64_t* i) -> int64_t {
  return __sync_sub_and_fetch(i, 1); // gcc/clang specific
}
namespace object { struct slots_t; } using object_t = object::slots_t*;
namespace object {
  struct slots_t {
    object_t klass;
    int64_t  retain_count;
  //unsigned weak_retain_count;

    auto incr() -> void {
      interlock_incr(&this->retain_count);
    }
    auto decr() -> void {
      if (0 == interlock_decr(&this->retain_count))
        delete this;
    }
    auto operator=(const slots_t& s) -> slots_t& {
      if (this != &s) {
        decr();
        this->retain_count = s.retain_count;
        incr();
      }
      return *this;
    }
    slots_t(const slots_t& s) : retain_count{s.retain_count} { incr(); }
    slots_t()                 : retain_count{0}              { incr(); }
    ~slots_t()                                               { decr(); }
  };
}
auto main() -> int {
  printf("%zu\n", sizeof(object::slots_t));
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

// Where weak_ptr interoperability is required a second counter
// (weak_count) is required in aux (will be incremented / decremented by
// weak_ptr), and delete pa must happen only when both the counters reach
// zero.



// clang++ -std=c++14 --warn-everything --warn-no-c++98-compat --warn-no-old-style-cast --output shared-ptr shared-ptr.cc
