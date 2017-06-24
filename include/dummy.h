// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# pragma once

# include <cstdint> // uintptr_t

# include "declare-klass-type.h"

dkt_declare_klass_type_typealias(boole,    bool);
dkt_declare_klass_type_typealias(char8,    char);
dkt_declare_klass_type_typealias(selector, ssize_t);
dkt_declare_klass_type_typealias(str,      const char*);
dkt_declare_klass_type_typealias(symbol,   const char*);
dkt_declare_klass_type_typealias(uchar8,   unsigned char);

KLASS_NS object { struct [[_dkt_typeinfo_]] slots_t; }
KLASS_NS object { typealias slots_t = struct slots_t; }

dkt_declare_klass_type_struct(klass);
dkt_declare_klass_type_struct(named_info);
dkt_declare_klass_type_struct(signature);
dkt_declare_klass_type_struct(super);

namespace method { typealias slots_t = FUNC (*)(object_t) -> object_t; }
typealias method_t = method::slots_t;
