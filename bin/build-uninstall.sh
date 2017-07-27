#!/bin/bash
set -o errexit -o nounset -o pipefail
if [[ -e cmake-binary-dir.txt ]]; then
  binary_dir=$(cat cmake-binary-dir.txt)
  if [[ -e $binary_dir/install_manifest.txt ]]; then
    for file in $(cat $binary_dir/install_manifest.txt); do
      echo rm -f $file; rm -f $file
    done
  fi
fi
