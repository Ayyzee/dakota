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

import void dk_register_info(  named_info_node_t* registration_info);
import void dk_deregister_info(named_info_node_t* registration_info);

import method_t dk_method_for_selector(object_t object, selector_t selector);
import method_t dk_method_for_selector(super_t  arg0,   selector_t selector);

import void dk_unbox_check(object_t object, object_t kls);
