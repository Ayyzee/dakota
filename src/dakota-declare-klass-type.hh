# if !defined dkt_dakota_declare_klass_type_hh
# define      dkt_dakota_declare_klass_type_hh

# include <dakota-decl.hh>

# define dkt_declare_klass_type_typealias(k, t) namespace k { using slots_t = t;                          } using k ## _t = k::slots_t
# define dkt_declare_klass_type_structptr(k)    namespace k { struct [[dkt_enable_typeinfo]] slots_t;     } using k ## _t = k::slots_t*
# define dkt_declare_klass_type_struct(k)       namespace k { struct [[dkt_enable_typeinfo]] slots_t;     } using k ## _t = k::slots_t
# define dkt_declare_klass_type_union(k)        namespace k { union  [[dkt_enable_typeinfo]] slots_t;     } using k ## _t = k::slots_t
# define dkt_declare_klass_type_enum(k, i)      namespace k { enum                           slots_t : i; } using k ## _t = k::slots_t
// not represented: func ptr typealias

# endif
