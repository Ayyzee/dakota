#if !defined dkt_dakota_declare_klass_type_hh
#define      dkt_dakota_declare_klass_type_hh

#if defined WIN32
  #define import __declspec(dllimport)
  #define export __declspec(dllexport)
#else
  #define import
  #define export __attribute__((__visibility__("default")))
#endif

#define dkt_declare_klass_type_typedef(k, t) namespace k { typedef t        slots_t;     } typedef k::slots_t  k##_t
#define dkt_declare_klass_type_structptr(k)  namespace k { struct    export slots_t;     } typedef k::slots_t* k##_t
#define dkt_declare_klass_type_struct(k)     namespace k { struct    export slots_t;     } typedef k::slots_t  k##_t
#define dkt_declare_klass_type_union(k)      namespace k { union     export slots_t;     } typedef k::slots_t  k##_t
#define dkt_declare_klass_type_enum(k, i)    namespace k { enum             slots_t : i; } typedef k::slots_t  k##_t
// not represented: function ptr typedef

#endif
