# if !defined dkt_dakota_declare_klass_type_hh
# define      dkt_dakota_declare_klass_type_hh

# include <dakota-decl.hh>

# define dkt_declare_klass_type_typedef(k, t) namespace k { typedef t                      slots_t;     } typedef k::slots_t  k ## _t
# define dkt_declare_klass_type_structptr(k)  namespace k { struct [[dkt_enable_typeinfo]] slots_t;     } typedef k::slots_t* k ## _t
# define dkt_declare_klass_type_struct(k)     namespace k { struct [[dkt_enable_typeinfo]] slots_t;     } typedef k::slots_t  k ## _t
# define dkt_declare_klass_type_union(k)      namespace k { union  [[dkt_enable_typeinfo]] slots_t;     } typedef k::slots_t  k ## _t
# define dkt_declare_klass_type_enum(k, i)    namespace k { enum                           slots_t : i; } typedef k::slots_t  k ## _t
// not represented: function ptr typedef

# endif
