#if !defined dkt_dakota_declare_klass_type_hh
#define      dkt_dakota_declare_klass_type_hh

#if defined WIN32
  #define SO_IMPORT __declspec(dllimport)
  #define SO_EXPORT __declspec(dllexport)
#else
  #define SO_IMPORT
  #define SO_EXPORT __attribute__((__visibility__("default")))
#endif
#define DKT_ENABLE_TYPEINFO SO_EXPORT

#define dkt_declare_klass_type_typedef(k, t) namespace k { typedef t                     slots_t;     } typedef k::slots_t  k##_t
#define dkt_declare_klass_type_structptr(k)  namespace k { struct    DKT_ENABLE_TYPEINFO slots_t;     } typedef k::slots_t* k##_t
#define dkt_declare_klass_type_struct(k)     namespace k { struct    DKT_ENABLE_TYPEINFO slots_t;     } typedef k::slots_t  k##_t
#define dkt_declare_klass_type_union(k)      namespace k { union     DKT_ENABLE_TYPEINFO slots_t;     } typedef k::slots_t  k##_t
#define dkt_declare_klass_type_enum(k, i)    namespace k { enum                          slots_t : i; } typedef k::slots_t  k##_t
// not represented: function ptr typedef

#endif
