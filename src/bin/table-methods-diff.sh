#!/bin/bash -u

rm -f methods1.txt methods2.txt

cp table.dk table.dk-rn
svn revert table.dk
touch table.dk
make install
../test/should-pass/table-methods/bin/exe | c++filt > methods1.txt

cp table.dk-rn table.dk
touch table.dk
make install
../test/should-pass/table-methods/bin/exe | c++filt > methods2.txt

diff methods1.txt methods2.txt
