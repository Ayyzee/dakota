#!/bin/bash

set -o errexit -o nounset -o pipefail

num=$(printf "%0.5i" $$)

dirs="should-pass/pass"

for dir in $dirs; do
  path=check-history/$dir/$num.txt
  echo $path >> check-history/$dir.txt
  bin/check.pl --output $path $dir/*/
  cat $path
done
