#if !defined __dakota_dummy_h__
#define      __dakota_dummy_h__

#include <cstdint> // uintptr_t

#include "dakota-declare-klass-type.h"

typedef int int_t;
typedef unsigned int uint_t;

dkt_declare_klass_type_typedef(boole,    bool);
dkt_declare_klass_type_typedef(char8,    char);
dkt_declare_klass_type_typedef(selector, uintptr_t);
dkt_declare_klass_type_typedef(symbol,   const char*);
dkt_declare_klass_type_typedef(uchar8,   unsigned char);

dkt_declare_klass_type_structptr(object);

dkt_declare_klass_type_struct(klass);
dkt_declare_klass_type_struct(named_info_node);
dkt_declare_klass_type_struct(signature);
dkt_declare_klass_type_struct(super);

namespace method { typedef object_t (*slots_t)(object_t); }
typedef method::slots_t method_t;

#endif
