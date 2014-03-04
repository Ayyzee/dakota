#!/bin/sh -u

#perl -p -i -0777 -e 's|export (slots .*;)|$1|gcm' *.dk
perl -p -i -0777 -e 's|export (slots )|$1|gcm' *.dk

cat dakota.dk | grep -v SLOTSSLOTS > dakota.dk-new
mv dakota.dk-new dakota.dk
