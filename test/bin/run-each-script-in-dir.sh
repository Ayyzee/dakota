#!/bin/bash

set -o errexit -o nounset -o pipefail

if [[ $# == 1 && $1 =~ /\*/ ]]; then
  # no path matches
  exit 0
fi

for path in $@; do
  dir=$(dirname $path)
  script=$(basename $path)
  echo_cmd="pushd $dir; ./$script; popd"
  cmd="pushd $dir >/dev/null; ./$script; popd>/dev/null"
  echo $echo_cmd
  eval $cmd
done
