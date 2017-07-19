#!/bin/bash
set -o errexit -o nounset -o pipefail
../bin/cmake-clean.sh
binary_dir=.; if [[ $# == 1 ]]; then binary_dir=$1; fi
rootdir=..
../bin/cmake-configure.sh $binary_dir # different from autoconf configure
../bin/build-clean.sh
../bin/build-all.sh
