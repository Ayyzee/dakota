// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# pragma once

# include <dakota.h>

# define dkt_declare_klass_type_typealias(k, t) namespace k { typealias slots_t = t;                  } typealias k ## _t = k::slots_t
# define dkt_declare_klass_type_struct(k)       namespace k { struct [[dkt_typeinfo]]   slots_t;      } typealias k ## _t = k::slots_t
# define dkt_declare_klass_type_union(k)        namespace k { union  [[dkt_typeinfo]]   slots_t;      } typealias k ## _t = k::slots_t
# define dkt_declare_klass_type_enum(k, i)      namespace k { enum   [[dkt_typeinfo]]   slots_t : i;  } typealias k ## _t = k::slots_t
// not represented: func ptr typealias
