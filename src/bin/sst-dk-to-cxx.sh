#!/bin/sh -u

if [ 0 -eq $# ]; then
    DK_PREFIX=. ./sst-dk-to-cxx.pl sst-dk-to-cxx.dk
else
    DK_PREFIX=. ./sst-dk-to-cxx.pl $@
fi
