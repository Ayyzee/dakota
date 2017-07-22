#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ -e make.sh ]]; then ./make.sh clean; fi
rootdir=..
$rootdir/bin/cmake-clean.sh
rm -f dakota.cmake # hackhack
$rootdir/bin/cmake-configure.sh
$rootdir/bin/build-clean.sh
time $rootdir/bin/build-all-dk.sh
