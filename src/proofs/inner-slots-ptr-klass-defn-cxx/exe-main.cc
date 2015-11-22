namespace outer {
  typedef int slots_t;
}
typedef outer::slots_t outer_t;

namespace outer {
  namespace inner {
    typedef slots_t* slots_t;
  }
  typedef inner::slots_t inner_t;
}
int main() {
  return 0;
}
