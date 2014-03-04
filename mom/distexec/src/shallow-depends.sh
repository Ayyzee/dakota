#!/bin/sh -u

#grep \#include *.cc *.h | shallow-depends.pl > doc/shallow-depends.dot
grep \#include *.h | shallow-depends.pl > doc/shallow-depends.dot
dot -Tps2 -o doc/shallow-depends.dot.ps doc/shallow-depends.dot
