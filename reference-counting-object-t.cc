// -*- mode: c++ -*-

# include <cassert>
# include <cstdio>
# include <cstdint>

# define cast(t) (t)

inline auto atomic_incr(int64_t* i) -> int64_t {
  return __sync_add_and_fetch(i, 1); // gcc/clang specific
}
inline auto atomic_decr(int64_t* i) -> int64_t {
  return __sync_sub_and_fetch(i, 1); // gcc/clang specific
}
namespace object { struct slots_t; }

struct object_t {
  object::slots_t* object;

  inline auto incr() -> void;
  inline auto decr() -> void;

  inline auto operator->() const -> object::slots_t* {
    return this->object;
  }
  inline auto operator*() const -> object::slots_t& {
    return *this->object;
  }
  inline auto operator=(const object_t& rval) -> object_t& {
    if (this != &rval) {
      this->object = rval.object;
      if (nullptr != this->object)
        incr();
    }
    return *this;
  }
  inline object_t(const object_t& rval) {
    this->object = rval.object;
    if (nullptr != this->object)
      incr();
  }
  inline object_t(object::slots_t* o) {
    this->object = o;
    if (nullptr != this->object)
      incr();
  }
  inline object_t() {
    this->object = nullptr;
  }
  inline ~object_t() {
    if (nullptr != this->object)
      decr();
  }
};
namespace object { struct slots_t { object_t klass; int64_t count; }; } // defined elsewhere

inline auto object_t::incr() -> void {
  assert(nullptr != this->object);
  atomic_incr(&this->object->count);
}
inline auto object_t::decr() -> void {
  assert(nullptr != this->object);
  assert(0 < this->object->count);
  atomic_decr(&this->object->count);
  if (0 == this->object->count) {
    printf("%i: %p: %s(): count=%lli\n", __LINE__, cast(void*)this, "DELETE", this->object->count);
    // dealloc(this->object);
  }
}
static auto make(object_t klass) -> object_t {
  object_t result;
  result.object = cast(object::slots_t*)malloc(sizeof(object::slots_t));
  *(result.object) = { .klass = klass, .count = 1 };
  return result;
}
// --test--
static auto foo(object_t o1) -> void {
  object_t o2 = o1;
}
static auto tst() -> void {
  object_t o;
  object_t o1 = make({});
  object_t o2 = o1;
  object_t o3;
  o3 = o1;
  foo(o3);
}
auto main() -> int {
  tst();
  return 0;
}
// clang++ -std=c++14 --warn-everything --warn-no-c++98-compat --warn-no-old-style-cast --warn-no-c99-extensions --debug=3 --output reference-counting-object-t.cc reference-counting-object-t.cc.cc
