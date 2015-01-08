#if !defined __dakota_dummy_h__
#define      __dakota_dummy_h__

#include <cstdint> // uintptr_t

#define KLASS namespace
#define TRAIT namespace

#define declare_klass_type_typedef(k, t) KLASS k { typedef t slots_t; } typedef k::slots_t  k##_t
#define declare_klass_type_structp(k)    KLASS k { struct    slots_t; } typedef k::slots_t* k##_t
#define declare_klass_type_struct(k)     KLASS k { struct    slots_t; } typedef k::slots_t  k##_t

typedef int int_t;
typedef unsigned int uint_t;

declare_klass_type_typedef(boole, bool);
declare_klass_type_typedef(char8, char);
declare_klass_type_typedef(selector, uintptr_t);
declare_klass_type_typedef(symbol, const char*);
declare_klass_type_typedef(uchar8, unsigned char);

declare_klass_type_structp(object);

declare_klass_type_struct(super);
declare_klass_type_struct(klass);
declare_klass_type_struct(signature);
declare_klass_type_struct(named_info_node);

KLASS method { typedef object_t (*slots_t)(object_t); }
typedef method::slots_t method_t;

#endif
