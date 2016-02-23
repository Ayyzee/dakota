# if !defined dkt_dakota_dummy_hh
# define      dkt_dakota_dummy_hh

# include <cstdint> // uintptr_t

# include "dakota-declare-klass-type.hh"

dkt_declare_klass_type_typealias(boole,    bool);
dkt_declare_klass_type_typealias(char8,    char);
dkt_declare_klass_type_typealias(selector, ssize_t);
dkt_declare_klass_type_typealias(str,      const char*);
dkt_declare_klass_type_typealias(symbol,   const char*);
dkt_declare_klass_type_typealias(uchar8,   unsigned char);

dkt_declare_klass_type_structptr(object);

dkt_declare_klass_type_struct(klass);
dkt_declare_klass_type_struct(named_info);
dkt_declare_klass_type_struct(signature);
dkt_declare_klass_type_struct(super);

namespace method { using slots_t = FUNC (*)(object_t) -> object_t; }
using method_t = method::slots_t;

# endif
