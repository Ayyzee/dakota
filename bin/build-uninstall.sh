#!/bin/bash
set -o errexit -o nounset -o pipefail
ee() {
  echo $1
  eval $1
}
if [[ -e ../.binary-dir.txt ]]; then
  binary_dir=$(cat ../.binary-dir.txt)
else
  binary_dir=build-cmk
fi
if [[ -e $binary_dir/install_manifest.txt ]]; then
  for file in $(cat $binary_dir/install_manifest.txt); do
    ee "rm -f $file"
  done
fi
