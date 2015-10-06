#!/bin/bash

set -o nounset -o errexit -o pipefail

srcs='dakota.dk lexer.dk'

for src in $srcs ; do
  bin/scrub.pl < $src > /tmp/$src
  diff $src /tmp/$src || /usr/bin/true
done

for src in $srcs ; do
  wc $src
  wc /tmp/$src
done
