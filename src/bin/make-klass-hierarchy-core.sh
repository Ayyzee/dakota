#!/bin/sh -u

files="\
ctlg/abstract-klass.ctlg \
ctlg/dakota.ctlg \
ctlg/klass.ctlg \
ctlg/object.ctlg \
ctlg/string.ctlg \
"

file="klass-hierarchy-core"

make-klass-hierarchy.pl --output $file.dot $files
open $file.dot
dot -o $file.ps -Tps2 $file.dot
open $file.ps

file="$file-simple"

make-klass-hierarchy.pl --simple --output $file.dot $files
open $file.dot
dot -o $file.ps -Tps2 $file.dot
open $file.ps
