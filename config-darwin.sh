#!/bin/bash
set -o errexit -o nounset -o pipefail

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

so_ext=dylib
CPFLAGS="-pr"
LNFLAGS="-s"
MKDIRFLAGS="-p"
RMFLAGS="-fr"
