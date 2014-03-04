#!/bin/sh -u

../bin/perl-call-graph.pl < ../bin/dakota > ../doc/dakota.dot
../bin/perl-call-graph.pl < ../bin/Dakota.pm | grep -v "dk::print" > ../doc/Dakota.pm.dot
pushd ../doc
make dakota.dot dakota.dot.ps
open dakota.dot dakota.dot.ps
make Dakota.pm.dot Dakota.pm.dot.ps
open Dakota.pm.dot Dakota.pm.dot.ps
popd
