#!/bin/sh -u

for path in $@; do
    name=$(basename $path)
    DK_PREFIX=.. ../lib/dakota/macro_system.pm $path
    echo "diff $path obj-macro-system/$name"
    diff $path obj-macro-system/$name.cc
    echo "wc -l $path obj-macro-system/$name"
    wc -l $path obj-macro-system/$name.cc
    /bin/echo "---"
done
