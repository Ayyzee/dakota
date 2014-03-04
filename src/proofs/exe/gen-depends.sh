#!/bin/sh -u

file=depends

DK_DEPENDS_OUTPUT_FILE=$file make clean all
./gen-depends.pl < $file > $file.dot
dot -Tpng -o $file.png $file.dot
open $file.png
