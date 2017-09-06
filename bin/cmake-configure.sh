#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ ! -e .build-dir.txt ]]; then
  build_dir=zzz/build
  echo $build_dir > .build-dir.txt
fi
build_dir=$(cat .build-dir.txt)
generator_id="${generator_id:-Ninja}"
if [[ ${generator:-ninja} == make ]]; then
  generator_id="Unix Makefiles"
fi
extra_opts="-DCMAKE_BUILD_TYPE=Debug -Wdev -Wdeprecated"
source_dir=$(pwd)
mkdir -p $build_dir
cd $build_dir
cmake -G "$generator_id" $extra_opts $source_dir
