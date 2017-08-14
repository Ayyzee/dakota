#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ -e ../cmake-binary-dir.txt ]]; then
  binary_dir=$(cat ../cmake-binary-dir.txt)
else
  binary_dir=build-cmk
  echo $binary_dir > ../cmake-binary-dir.txt
fi
rel_source_dir=..
generator_id="${generator_id:-Ninja}"
if [[ ${generator:-ninja} == make ]]; then
  generator_id="Unix Makefiles"
fi
extra_opts="-DCMAKE_BUILD_TYPE=Debug -Wdev -Wdeprecated"
mkdir -p $binary_dir
cd $binary_dir
cmake -G "$generator_id" $extra_opts $rel_source_dir
