#!/bin/bash

git checkout *.dk *.hh ../include/*.hh

#perl -p -i -e 's/(static|inline) ([\w-]+-t)\s+([\w-]+\(.+?\))\s*(;| {)/$1 func $3 -> $2$4/g' *.dk
#perl -p -i -e 's/(void|(const )?[\w-]+-t)\s+([\w-]+\(.+?\))\s*(;| {)/func $3 -> $1$4/g' *.dk
#exit

perl -p -i -e 's/klass(\s+)uint32/__KLASS$1UINT32__/g' *.dk
perl -p -i -e 's/klass(\s+)int32/__KLASS$1INT32__/g' *.dk

perl -p -i -e 's/uint32-value/int64-value/g' *.dk
perl -p -i -e 's/int32-value/int64-value/g' *.dk

perl -p -i -e 's/uint32-t  /int64-t   /g' *.dk
perl -p -i -e 's/uint32_t  /int64_t   /g' *.dk
perl -p -i -e 's/uint32-t/int64-t/g' *.dk
perl -p -i -e 's/uint32_t/int64_t/g' *.hh ../include/*.hh

perl -p -i -e 's/uint32::/int64::/g' *.dk *.hh ../include/*.hh

perl -p -i -e 's/int32-t  /int64-t   /g' *.dk
perl -p -i -e 's/int32_t  /int64_t   /g' *.dk
perl -p -i -e 's/int32-t/int64-t/g' *.dk
perl -p -i -e 's/int32_t/int64_t/g' *.hh ../include/*.hh

perl -p -i -e 's/int32::/int64::/g' *.dk *.hh ../include/*.hh

perl -p -i -e 's/__KLASS(\s+)UINT32__/klass$1uint32/g' *.dk
perl -p -i -e 's/__KLASS(\s+)INT32__/klass$1int32/g' *.dk

git checkout module-dakota*.dk

# bit-vector.dk:reverse-32(int64-t arg)
