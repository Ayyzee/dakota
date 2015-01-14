#if !defined __dakota_declare_klass_type_h__
#define      __dakota_declare_klass_type_h__

#define dkt_declare_klass_type_typedef(k, t) namespace k { typedef t slots_t;     } typedef k::slots_t  k##_t
#define dkt_declare_klass_type_structptr(k)  namespace k { struct    slots_t;     } typedef k::slots_t* k##_t
#define dkt_declare_klass_type_struct(k)     namespace k { struct    slots_t;     } typedef k::slots_t  k##_t
#define dkt_declare_klass_type_union(k)      namespace k { union     slots_t;     } typedef k::slots_t  k##_t
#define dkt_declare_klass_type_enum(k, i)    namespace k { enum      slots_t : i; } typedef k::slots_t  k##_t
// not represented: function ptr typedef

#endif
