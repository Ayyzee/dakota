#!/bin/sh -u

DOT_PS_PRINT_FLAGS="-Gpage=8.5,11 -Gsize=10,7.5 -Grotate=90"

./dot-ps-print-common.sh "$DOT_PS_PRINT_FLAGS" $@
