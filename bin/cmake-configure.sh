#!/bin/bash
set -o errexit -o nounset -o pipefail
rel_source_dir=.
binary_dir=$rel_source_dir; if [[ $# == 1 ]]; then binary_dir=$1; fi
echo $binary_dir > cmake-binary-dir.txt
extra_opts="-Wdev -Wdeprecated"

if [[ $binary_dir != '.' && $binary_dir != '..' ]]; then
  mkdir -p $binary_dir
  cd $binary_dir
  rel_source_dir=..
fi
cmake $extra_opts $rel_source_dir
