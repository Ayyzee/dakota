#!/bin/bash
set -o errexit -o nounset -o pipefail
ee() {
  echo $1
  eval $1
}
if [[ -e .build-dir.txt ]]; then
  build_dir=$(cat .build-dir.txt)
else
  build_dir=z/build
fi
if [[ -e $build_dir/install_manifest.txt ]]; then
  for file in $(cat $build_dir/install_manifest.txt); do
    ee "rm -f $file"
  done
fi
