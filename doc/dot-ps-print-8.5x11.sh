#!/bin/sh -u

DOT_PS_PRINT_FLAGS="-Gpage=8.5,11 -Gsize=7.5,10"

./dot-ps-print-common.sh "$DOT_PS_PRINT_FLAGS" $@
