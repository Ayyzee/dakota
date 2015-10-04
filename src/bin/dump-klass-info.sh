#!/bin/sh -u

if [ -e lib/libdakota.$so_ext ]; then
    echo "//  lib/libdakota.$so_ext"
    dakota-info --only $1 lib/libdakota.$so_ext
else
    echo "//  /usr/local/lib/libdakota.$so_ext"
    dakota-info --only $1 /usr/local/lib/libdakota.$so_ext
fi


