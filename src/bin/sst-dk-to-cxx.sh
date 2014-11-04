#!/bin/sh -u

for path in $@; do
    name=$(basename $path)
    DK_PREFIX=.. bin/sst-dk-to-cxx.pl $path > /tmp/$name
    echo "diff $path /tmp/$name"
    diff $path /tmp/$name
    echo "wc -l $path /tmp/$name"
    wc -l $path /tmp/$name
    /bin/echo "---"
done
