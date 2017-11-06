#!/bin/bash
finish() {
  rm /tmp/stdout-$$.txt
}
trap finish EXIT
set -o errexit -o nounset -o pipefail
if [[ ! -e .build-dir.txt ]]; then
  rel_build_dir=z/build
  echo $rel_build_dir > .build-dir.txt
fi
rel_build_dir=$(cat .build-dir.txt)
generator_id="${generator_id:-Ninja}"
if [[ ${generator:-ninja} == make ]]; then
  generator_id="Unix Makefiles"
fi
extra_opts="-DCMAKE_BUILD_TYPE=Debug -Wdev -Wdeprecated"
source_dir=$(pwd)
mkdir -p $rel_build_dir
cd $rel_build_dir
cmake -G "$generator_id" $extra_opts $source_dir > /tmp/stdout-$$.txt
