#!/bin/bash
set -o errexit -o nounset -o pipefail

dir=.
if [[ 1 == $# ]]; then
  dir=$1
fi
echo $dir > cmake-build-dir.txt
rootdir=..
$rootdir/bin/dakota-build2project dakota.build   > dakota.project
$rootdir/bin/dakota-build2cmk     dakota.project > dakota.cmk
extra_opts="-Wdev -Wdeprecated"
cmake $extra_opts $dir
