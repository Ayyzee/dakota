#!/bin/bash
set -o errexit -o nounset -o pipefail
dir=.; if [[ $# == 1 ]]; then dir=$1; fi
echo $dir > cmake-build-dir.txt
rootdir=$HOME/dakota
$rootdir/bin/dakota-build2project $dir/dakota.build   > $dir/dakota.project
$rootdir/bin/dakota-build2cmk     $dir/dakota.project > $dir/dakota.cmk
extra_opts="-Wdev -Wdeprecated"
cmake $extra_opts $dir
