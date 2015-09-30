#!/bin/bash

set -o nounset -o pipefail

dirs="\
 should-pass/pass/add-method-on-object\
 should-pass/pass/add-method-on-string\
"

if [[ $# > 0 ]]; then
  dirs=$@
fi

for dir in $dirs; do
  echo "### \"$dir/\""
  make --directory $dir clean
  make $dir/exe
  make --directory $dir check
done
