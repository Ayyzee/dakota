#!/bin/bash
set -o errexit -o nounset -o pipefail
./cmake-clean.sh
binary_dir=.; if [[ $# == 1 ]]; then binary_dir=$1; fi
rootdir=..
$rootdir/bin/dakota-cmake2project dakota.cmake dakota.project
./cmake-configure.sh $binary_dir # different from autoconf configure
./build-clean.sh
./build-all.sh
