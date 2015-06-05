#!/bin/sh -u

so_ext=${dk_so_ext:-so}

if [ $so_ext = "dylib" ] ; then
    # darwin
    opts="-g"
    nm $opts ../lib/libdakota-util.$so_ext | c++filt | grep -v " U " | grep -v \.eh | grep -v "typeinfo " | sort -k 3
else
    opts="--extern-only --demangle --line-numbers --defined-only"
    nm $opts ../lib/libdakota-util.$so_ext | grep -v " _rest" | grep -v " _save" | grep -v "typeinfo "
fi
