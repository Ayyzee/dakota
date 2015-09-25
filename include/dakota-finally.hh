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

#if !defined dkt_dakota_finally_hh
#define      dkt_dakota_finally_hh

// http://www.codeproject.com/Tips/476970/finally-clause-in-Cplusplus

#include <functional>

class finally {
    std::function<void(void)> functor;
  public:
    finally(const std::function<void(void)> &ftor) : functor(ftor) {}
    ~finally() { functor(); }
};

#define DKT_FINALLY(block) finally __finally([&] block)

#define DKT_CATCH_BEGIN(_e_) catch (object_t _e_) { if (0) {}
#define DKT_CATCH(kls, v)    else if (dk::instancex3f(v, kls))
#define DKT_CATCH_END(_e_)   else { throw _e_; } }
#endif
