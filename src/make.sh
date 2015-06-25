#!/bin/bash

set -o nounset -o errexit -o pipefail

MAKE=make
MAKEFLAGS="\
 --no-builtin-rules\
 --no-builtin-variables\
 --warn-undefined-variables\
"

$MAKE $MAKEFLAGS $@
