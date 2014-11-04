#!/bin/sh

set -o xtrace

DK_MACROS_PATH=./macros-test.pl bin/sst-dk-to-cxx.sh macros-test.dk
cat macros-test.dk
cat /tmp/macros-test.dk
