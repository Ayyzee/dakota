#!/bin/bash
set -o errexit -o nounset -o pipefail
binary_dir=$(cat cmake-binary-dir.txt)
jobs=$(getconf _NPROCESSORS_ONLN)
#INSTALL_PREFIX=${INSTALL_PREFIX-$HOME} make --directory $binary_dir --jobs $jobs $@
INSTALL_PREFIX=$HOME make --directory $binary_dir --jobs $jobs $@
