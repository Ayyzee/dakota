#!/bin/sh -u

if [ -e lib/libdakota.$SO_EXT ]; then
    echo "//  lib/libdakota.$SO_EXT"
    dakota-introspector --only $1 lib/libdakota.$SO_EXT
else
    echo "//  /usr/local/lib/libdakota.$SO_EXT"
    dakota-introspector --only $1 /usr/local/lib/libdakota.$SO_EXT
fi


