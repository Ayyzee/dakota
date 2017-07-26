#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ -e make.sh ]]; then ./make.sh clean; fi
rootdir=..
$rootdir/bin/cmake-configure.sh
$rootdir/bin/build.sh clean
$rootdir/bin/build.sh all
