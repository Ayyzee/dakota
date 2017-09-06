#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ ! -e .binary-dir.txt ]]; then
  binary_dir=zzz/build
  echo $binary_dir > .binary-dir.txt
fi
binary_dir=$(cat .binary-dir.txt)
generator_id="${generator_id:-Ninja}"
if [[ ${generator:-ninja} == make ]]; then
  generator_id="Unix Makefiles"
fi
extra_opts="-DCMAKE_BUILD_TYPE=Debug -Wdev -Wdeprecated"
source_dir=$(pwd)
mkdir -p $binary_dir
cd $binary_dir
cmake -G "$generator_id" $extra_opts $source_dir
