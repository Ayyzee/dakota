#!/bin/bash
set -o errexit -o nounset -o pipefail

parts=$1
shift

cat /dev/null > $parts

for arg in $@; do
  if [[ $arg =~ :$ ]]; then
    echo $arg >> $parts
  else
    echo "  -" $arg >> $parts
  fi
done
