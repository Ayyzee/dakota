#!/bin/sh -u

bname="klass-hierarchy"

make-klass-hierarchy.pl --output $bname.dot $@
open $bname.dot
dot -Tps2 -o $bname.ps $bname.dot
open $bname.ps

bname="$bname-simple"

make-klass-hierarchy.pl --simple --output $bname.dot $@
open $bname.dot
dot -Tps2 -o $bname.ps $bname.dot
open $bname.ps
