#!/bin/bash
set -o errexit -o nounset -o pipefail

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

source $DIR/common.sh

so_ext=dylib
CXX_SHARED_FLAGS="-dynamiclib"
CXX_DYNAMIC_FLAGS="-dynamiclib"
CPFLAGS="-pr"
LNFLAGS="-s"
MKDIRFLAGS="-p"
RMFLAGS="-fr"
