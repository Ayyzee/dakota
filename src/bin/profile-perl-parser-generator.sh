#!/bin/sh

make clean
rm -f tmon.out
export dk_ext=dk
export PATH=../bin:$PATH
perl -d:DProf ../bin/dakota  --precompile --shared --output lib/libdakota.$so_ext abstract-klass.dk ascii-number-klass.dk ascii-number.dk association.dk collection.dk counted-element.dk counted-set.dk dakota.dk deque.dk exception.dk forward-iterator.dk hashed-counted-set.dk hashed-set.dk hashed-table.dk input-stream.dk int32.dk intptr.dk klass.dk no-such-method-exception.dk null.dk object-input-stream.dk object-output-stream.dk object.dk output-stream.dk perl/parser.dk rect.dk sequence.dk serialization-handler.dk set.dk sorted-counted-set.dk sorted-set.dk sorted-table.dk stack.dk string.dk table.dk token.dk uint32.dk uintptr.dk vector.dk xml/element.dk xml/parser.dk /usr/local/lib/libexpat.$so_ext
echo "###"
dprofpp
