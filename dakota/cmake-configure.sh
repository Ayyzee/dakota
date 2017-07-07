#!/bin/bash
set -o errexit -o nounset -o pipefail

rootdir=..
$rootdir/bin/dakota-build2project dakota.build   > dakota.project
$rootdir/bin/dakota-build2cmk     dakota.project > dakota.cmk

extra_opts="-Wdev -Wdeprecated"

cmake $extra_opts $@ .
