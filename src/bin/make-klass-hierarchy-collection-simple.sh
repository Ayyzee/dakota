#!/bin/sh -u

bname="klass-hierarchy-collection"

cat /dev/null > common.ctlg

klses=`cat $bname.txt`

for kls in $klses; do
    bin/dakota-info --only $kls --noslots --nomethods lib/libdakota.dylib      >> common.ctlg
    bin/dakota-info --only $kls --noslots --nomethods lib/libdakota-util.dylib >> common.ctlg
done

#bin/make-klass-hierarchy.pl --output $bname.dot common.ctlg
#open $bname.dot
#dot -Tps2 -o $bname.dot.ps $bname.dot
#open $bname.dot.ps

bname="$bname-simple"

bin/make-klass-hierarchy.pl --simple --output $bname.dot common.ctlg
#open $bname.dot
dot -Tps2 -o $bname.dot.ps $bname.dot
open $bname.dot.ps
