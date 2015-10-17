#!/bin/bash

set -o errexit -o nounset -o pipefail

log_line=($(git log -1 --format=oneline))
sha1=${log_line[0]}

num=$(printf "%0.5i" $$)

dirs="should-pass/pass"

for dir in $dirs; do
  path=check-history/$dir/$num.txt
  export SHA1=$sha1
  bin/check.pl --output $path $dir/*/
  echo "$path $sha1" >> check-history/$dir.txt
  cat $path
done
