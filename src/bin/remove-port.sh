#!/bin/sh -u

 perl -p -i -0777 -e 's/noexport\s+(klass|slots|method)(\s+)/$1$2/gcm' *.dk
 perl -p -i -0777 -e 's/\bexport\s+//gcm' *.dk
#perl -p -i -0777 -e 's/export\s+(klass|slots|method)(\s+)/$1$2/gcm' *.dk
#perl -p -i -0777 -e 's/import\s+(klass|slots|method).*?;\n//gcm' *.dk

perl -p -i -0777 -e 's/noexport /hide /gcm' *.dk
