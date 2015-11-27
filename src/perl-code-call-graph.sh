#!/bin/bash

set -o errexit -o nounset -o pipefail

#./perl-code-call-graph.pl  ../lib/dakota/{dakota,parse,rewrite,generate,sst,util}.pm > out.dot && open out.dot
./perl-code-call-graph.pl  ../lib/dakota/generate.pm > out.dot
wc -l out.dot

#dot  out.dot | ./perl-code-call-graph-area.pl

dot -Tpdf -o out.pdf out.dot
open out.pdf
