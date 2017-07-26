#!/bin/bash
set -o errexit -o nounset -o pipefail
binary_dir=$(cat cmake-binary-dir.txt)
for file in $(cat $binary_dir/install_manifest.txt); do
  echo rm -f $file; rm -f $file
done
