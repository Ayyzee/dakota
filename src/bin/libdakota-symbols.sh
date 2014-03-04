#!/bin/sh -u

SO_EXT=${DK_SO_EXT:-so}

if [ $SO_EXT = "dylib" ] ; then
    # darwin
    opts="-g"
    nm $opts ../lib/libdakota.$SO_EXT | c++filt | grep -v " U " | grep -v \.eh | grep -v "typeinfo " | sort -k 3
else
    opts="--extern-only --demangle --line-numbers --defined-only"
    nm $opts ../lib/libdakota.$SO_EXT | grep -v " _rest" | grep -v " _save" | grep -v "typeinfo "
fi
