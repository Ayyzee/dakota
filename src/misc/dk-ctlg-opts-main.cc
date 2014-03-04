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

#include <stdint.h>
#include <stdlib.h>
#include <getopt.h>
#include <stdio.h>

enum
  {
    opt_00 = 1 <<  0,
    opt_01 = 1 <<  1,
    opt_02 = 1 <<  2,
    opt_03 = 1 <<  3,
    opt_04 = 1 <<  4,
    opt_05 = 1 <<  5,
    opt_06 = 1 <<  6,
    opt_07 = 1 <<  7,
    opt_08 = 1 <<  8,
    opt_09 = 1 <<  9,

    opt_10 = 1 << 10,
    opt_11 = 1 << 11,
    opt_12 = 1 << 12,
    opt_13 = 1 << 13,
    opt_14 = 1 << 14,
    opt_15 = 1 << 15,
    opt_16 = 1 << 16,
    opt_17 = 1 << 17,
    opt_18 = 1 << 18,
    opt_19 = 1 << 19,

    opt_20 = 1 << 20,
    opt_21 = 1 << 21,
    opt_22 = 1 << 22,
    opt_23 = 1 << 23,
    opt_24 = 1 << 24,
    opt_25 = 1 << 25,
    opt_26 = 1 << 26,
    opt_27 = 1 << 27,
    opt_28 = 1 << 28,
    opt_29 = 1 << 29,

    opt_30 = 1 << 30,
    opt_31 = 1 << 31,
  };
static struct option longopts[] =
  {
    { "opt-00", no_argument, NULL, opt_00 },
    { "opt-01", no_argument, NULL, opt_01 },
    { "opt-02", no_argument, NULL, opt_02 },
    { "opt-03", no_argument, NULL, opt_03 },
    { "opt-04", no_argument, NULL, opt_04 },
    { "opt-05", no_argument, NULL, opt_05 },
    { "opt-06", no_argument, NULL, opt_06 },
    { "opt-07", no_argument, NULL, opt_07 },
    { "opt-08", no_argument, NULL, opt_08 },
    { "opt-09", no_argument, NULL, opt_09 },

    { "opt-10", no_argument, NULL, opt_10 },
    { "opt-11", no_argument, NULL, opt_11 },
    { "opt-12", no_argument, NULL, opt_12 },
    { "opt-13", no_argument, NULL, opt_13 },
    { "opt-14", no_argument, NULL, opt_14 },
    { "opt-15", no_argument, NULL, opt_15 },
    { "opt-16", no_argument, NULL, opt_16 },
    { "opt-17", no_argument, NULL, opt_17 },
    { "opt-18", no_argument, NULL, opt_18 },
    { "opt-19", no_argument, NULL, opt_19 },

    { "opt-20", no_argument, NULL, opt_20 },
    { "opt-21", no_argument, NULL, opt_21 },
    { "opt-22", no_argument, NULL, opt_22 },
    { "opt-23", no_argument, NULL, opt_23 },
    { "opt-24", no_argument, NULL, opt_24 },
    { "opt-25", no_argument, NULL, opt_25 },
    { "opt-26", no_argument, NULL, opt_26 },
    { "opt-27", no_argument, NULL, opt_27 },
    { "opt-28", no_argument, NULL, opt_28 },
    { "opt-29", no_argument, NULL, opt_29 },

    { "opt-30", no_argument, NULL, opt_30 },
    { "opt-31", no_argument, NULL, opt_31 },

    { NULL, 0, NULL, 0 }
  };

static uint32_t
handle_opts(struct option* longopts, int* argc, char*** argv)
{
  uint32_t result = 0;
  int unrecognized_opt_cnt = 0;
  int opt;

  while (-1 != (opt = getopt_long(*argc, *argv, "", longopts, NULL)))
  {
    switch (opt)
    {
      case opt_00: case opt_01: case opt_02: case opt_03: case opt_04:
      case opt_05: case opt_06: case opt_07: case opt_08: case opt_09:

      case opt_10: case opt_11: case opt_12: case opt_13: case opt_14:
      case opt_15: case opt_16: case opt_17: case opt_18: case opt_19:

      case opt_20: case opt_21: case opt_22: case opt_23: case opt_24:
      case opt_25: case opt_26: case opt_27: case opt_28: case opt_29:

      case opt_30: case opt_31:
        result |= opt;
        break;
      default:
        unrecognized_opt_cnt++;
    }
  }
  *argc -= optind;
  *argv += optind;
  if (0 != unrecognized_opt_cnt)
    exit(EXIT_FAILURE);
  return result;
}

int
main(int argc, char** argv)
{
  uint32_t opts = handle_opts(longopts, &argc, &argv);
  char* lhs = "DK_CTLG_OPTS";
  char rhs[2 + 8 + (1)] = "";
  snprintf(rhs, sizeof(rhs), "0x%08x", opts);
  fprintf(stdout, "%s=%s\n", lhs, rhs);
  return 0;
}
