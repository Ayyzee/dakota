// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// Copyright (C) 2007, 2008, 2009 Robert Nielsen <robert@dakota.org>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#if !defined __dakota_before_user_code_h__
#define      __dakota_before_user_code_h__

extern import object_t null;
extern import object_t std_input;
extern import object_t std_output;
extern import object_t std_error;

typedef boole_t (*type_predicate_t)(int_t);
typedef boole_t   (*equal_predicate_t)(object_t, object_t); //hackhack
typedef int_t  (*compare_t)(object_t, object_t); // comparitor
typedef uintmax_t (*hash_t)(object_t);

constexpr uintmax_t dk_hash(const char8_t* str, uintmax_t h = 0)
{ // Daniel J. Bernstein
  return !str[h] ? 5381 : ( dk_hash(str, h + 1) * 33 ) ^ (uchar8_t)(str[h]);
}

import symbol_t dk_intern(const char8_t*);
import void dkt_throw(object_t exception);
import void dkt_throw(const char8_t* exception_str);

import object_t             dk_klass_for_name(symbol_t);

#if defined DEBUG
#define DKT_NULL_METHOD nullptr
#else
import void dkt_null_method(object_t object, ...);
#define DKT_NULL_METHOD dkt_null_method
#endif

typedef const signature_t* (*dkt_signature_function_t)();
typedef selector_t* (*dkt_selector_function_t)();

#if defined DEBUG
import int_t dk_trace_before(const signature_t* signature, method_t method, super_t context, ...);
import int_t dk_trace_before(const signature_t* signature, method_t method, object_t object, ...);
import int_t dk_trace_after( const signature_t* signature, method_t method, super_t context, ...);
import int_t dk_trace_after( const signature_t* signature, method_t method, object_t object, ...);

import int_t dk_va_trace_before_init(object_t kls, va_list_t);
import int_t dk_va_trace_after_init( object_t kls, va_list_t);

import char8_t* dk_get_klass_chain(object_t klass, char8_t* buf, uint32_t buf_len);

import void dk_dump_methods(object_t);
import void dk_dump_methods(klass::slots_t*);
#endif

import void dk_export_klass(  named_info_node_t* klass_info);
import void dk_export_klasses(named_info_node_t* klass_info);

sentinel import object_t           dk_add_all(object_t self, ...);
sentinel import named_info_node_t* dk_make_named_info_slots(symbol_t name, ...);
sentinel import object_t           dk_make_named_info(symbol_t name, ...);

#endif // __dakota_before_user_code_h__
