#!/bin/bash
set -o errexit -o nounset -o pipefail
binary_dir=.; if [[ $# == 1 ]]; then binary_dir=$1; fi
rootdir=..
$rootdir/bin/cmake-clean.sh
$rootdir/bin/cmake-configure.sh $binary_dir # different from autoconf configure
$rootdir/bin/build-clean.sh
$rootdir/bin/build-all-dk.sh
