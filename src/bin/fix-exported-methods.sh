#!/bin/sh -u

perl -p -i -0777 -e 's|export (method )|$1|gcm' *.dk

cat dakota.dk | grep -v METHODMETHOD > dakota.dk-new
mv dakota.dk-new dakota.dk
