#if !defined __dakota_declare_klass_type_h__
#define      __dakota_declare_klass_type_h__

#define dkt_declare_klass_type_typedef(k, t) namespace k { typedef t slots_t; } typedef k::slots_t  k##_t
#define dkt_declare_klass_type_structptr(k)  namespace k { struct    slots_t; } typedef k::slots_t* k##_t
#define dkt_declare_klass_type_struct(k)     namespace k { struct    slots_t; } typedef k::slots_t  k##_t

#endif
