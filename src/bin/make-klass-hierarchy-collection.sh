#!/bin/sh -u

graph_klass_hierarchy()
{
    for name in $@; do
	bname=`basename -s .txt $name`
	cat /dev/null > "$bname.ctlg"
	
	klses=`cat $bname.txt`
	
	for kls in $klses; do
	    bin/dakota-info --only $kls lib/libdakota.$so_ext      >> "$bname.ctlg"
	    bin/dakota-info --only $kls lib/libdakota-util.$so_ext >> "$bname.ctlg"
	done
	
	cat /dev/null > "$bname.dot"
	cat /dev/null > "$bname.dot.ps"
	bin/make-klass-hierarchy.pl --output "$bname.dot" "$bname.ctlg"
        #open "$bname.dot"
	dot -Tps2 -o "$bname.dot.ps" "$bname.dot"
	open "$bname.dot.ps"
	
	cat /dev/null > "$bname-simple.dot"
	cat /dev/null > "$bname-simple.dot.ps"
	bin/make-klass-hierarchy.pl --simple --output "$bname-simple.dot" "$bname.ctlg"
        #open "$bname-simple.dot"
	dot -Tps2 -o "$bname-simple.dot.ps" "$bname-simple.dot"
	open "$bname-simple.dot.ps"
    done
}

if [ 0 = $# ]; then
    graph_klass_hierarchy "klass-hierarchy-collection.txt"
else
    graph_klass_hierarchy $@
fi
