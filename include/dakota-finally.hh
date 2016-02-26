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

# if !defined dkt_dakota_finally_hh
# define      dkt_dakota_finally_hh

// http://the-witness.net/news/2012/11/scopeexit-in-c11

template <typename F>
struct finally_t {
  F _f;
  finally_t(const finally_t&) = default;
  finally_t(F f) : _f(f) {}
  ~finally_t() { _f(); }
};
template <typename F>
finally_t<F> finally(F f) {
  return finally_t<F>(f);
};

// try {
// }
// ...
// catch (more-specific-thing::klass e1) {
// }
// catch (less-specific-thing::klass e2) {
// }
// ...
// catch (...) {
// }
// finally {
// }

# define DKT_CATCH_BEGIN(e) catch (object_t e) { if (0) {}
# define DKT_CATCH(k, e)    else if (dk::instance3f(e, k)) // dk::instance?(e, k)
# define DKT_CATCH_END(e)   else { throw; } }
# define DKT_FINALLY(block) auto _finally_ = finally([&]() block)

# endif
