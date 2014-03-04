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

#ifndef __tags_h__
#define __tags_h__

enum tag_t
{
  null_tag =     0x0,
  exec_work =    0x1,
  have_work =    0x2,
  need_work =    0x3,
  exit_value =   0x4,
  no_work =      0x5,
  exec_work_id = 0x6,
  child_stdin =  0x7,
  child_stdout = 0x8,
  child_stderr = 0x9,
  generic =      0xa,
  ack =          0xb
};
typedef enum tag_t tag_t;

#endif
