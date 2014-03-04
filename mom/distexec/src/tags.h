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
  null_tag  =  0x0,
  exec_work =  0x1,
  have_work =  0x2,
  need_work =  0x3,
  exit_value = 0x4,
  no_work    = 0x5,
  exec_work_id = 0x6,
  child_stdin = 0x7,
  child_stdout = 0x8,
  child_stderr = 0x9,
  generic = 0xa,
  ack = 0xb
};
typedef enum tag_t tag_t;

// ttttllllvvvvvvvv

// exec_work_id: ttttllll

// lc: loopback client
// ls: loopback server
// mc: multicast client
// ms: multicast server
// uc: unicast client
// us: unicast server
// pp: parent process
// cp: child process

// ***

// lc >> ls {exec-work[*]}
// lc << ls {exit-value[value]}

// mc >> ms {have-work}|{have-no-work}|{need-work}
// mc << ms <none>

// uc >> us {need-work}|{exit-value[id][value]}
// uc << us {exec-work[id][*]}|{have-no-work}

// ***

// <= or => : establish connection if needed and use
// <- or -> : use established connection

// ***

// lc => ls             {exec-work[*]}
//       mc -> ms       {have-work}
//       us <= uc       {need-work}
//       us -> uc       {exec-work[id][*]}
//             pp => cp {exec-work[*]}
//             pp <- cp {exit-value[value]}
//       us <- uc       {exit-value[id][value]}
// lc <- ls             {exit-value[value]}

// ***

// lc_snd     -> lc_rcv ()
// lc_rcv     -> (terminal)
// ls_rcv     -> mc_snd ()
// ls_snd     -> (terminal)
// mc_snd     -> us_rcv-1
// ms_rcv     -> uc_snd-1 ()
// uc_snd-1   -> uc_rcv
// uc_rcv     -> child_exit
// child_exit -> uc_snd-2
// uc_snd-2   -> (terminal)
// us_rcv-1   -> us_snd
// us_snd     -> us_rcv-2
// us_rcv-2   -> ls_snd

#endif
