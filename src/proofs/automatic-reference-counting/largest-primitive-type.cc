template<typename... TYPES>
class pack
{};

typedef pack<float, double, long double, unsigned short, unsigned int,
             unsigned long, unsigned long long, short, int, long, long long> primitive_types;

////

template<typename L, typename R>
class smaller
{
public:
  static const bool value = sizeof(L) < sizeof(R);
};

////

