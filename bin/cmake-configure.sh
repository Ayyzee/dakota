#!/bin/bash
set -o errexit -o nounset -o pipefail
binary_dir=build-cmk
rel_source_dir=..
echo $binary_dir > cmake-binary-dir.txt
extra_opts="-DCMAKE_BUILD_TYPE=Debug -Wdev -Wdeprecated"
mkdir -p $binary_dir
cd $binary_dir
cmake $extra_opts $rel_source_dir
