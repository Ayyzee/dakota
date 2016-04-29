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

# if !defined dkt-dakota-private-hh
# define      dkt-dakota-private-hh

# include "dakota-dummy.hh"
# include "dakota.hh"

dkt-declare-klass-type-struct(selector-node);
//dkt-declare-klass-type-struct(signature);

func import-selectors(signature-t** signatures, selector-node-t* selector-nodes) -> void;

func interposer-name-for-klass-name(symbol-t klass-name) -> symbol-t;
func add-interpose-prop(symbol-t key, symbol-t element) -> void;

func info-for-name(symbol-t) -> named-info-t*;

func safe-strptrcmp(const str-t* sp1, const str-t* sp2) -> int-t;
func safe-strncmp(str-t s1, str-t s2, size-t n) -> int-t;

func safe-strcmp(str-t, str-t) -> int-t;
func safe-strlen(str-t) -> size-t;

func strerror-name(int-t errnum) -> str-t;

func size-from-info(named-info-t* info) -> int64-t;
func offset-from-info(named-info-t* info) -> int64-t;
func name-from-info(named-info-t* info) -> symbol-t;
func klass-name-from-info(named-info-t* info) -> symbol-t;
func superklass-name-from-info(named-info-t* info) -> symbol-t;
func superklass-name-from-info(named-info-t* info, symbol-t name) -> symbol-t;

func default-superklass-name() -> symbol-t;
func default-klass-name() -> symbol-t;

func selector-count() -> int64-t;

klass object {
  method dump(object-t) -> object-t;
  method instance?(object-t, object-t) -> boole-t; // instance?()
}
klass klass {
  method init(object-t, named-info-t*) -> object-t;
  method subklass?(object-t, object-t) -> boole-t; // subklass?()
}
klass bit-vector {
  method set-bit(object-t, ssize-t, boole-t) -> object-t;
}
# if DKT-WORKAROUND
klass property {
  method compare(slots-t*,  slots-t* ) -> int-t;
}
klass named-info {
  func compare(slots-t**, slots-t**) -> int-t;
}
# endif

[[noreturn]] func verbose-terminate()  noexcept -> void;
[[noreturn]] func verbose-unexpected() noexcept -> void;
[[noreturn]] func pre-runtime-verbose-terminate() noexcept -> void;
[[noreturn]] func pre-runtime-verbose-unexpected() noexcept -> void;

inline func root-superklass?(object-t object) -> boole-t {
  if (nullptr == object || null == object)
    return true;
  else
    return false;
} // root-superklass?()

# endif // dkt-dakota-private-hh
