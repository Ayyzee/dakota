#!/bin/sh -u

perl -p -i -0777 -e 's|\t|  |gcm' *.dk
perl -p -i -0777 -e 's|( )( +)=|$1=$2|gcm' *.dk
perl -p -i -0777 -e 's| +\n|\n|gcm' *.dk
# if/for/while (
