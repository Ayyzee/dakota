#!/bin/sh -u

#depends.pl *.cc *.h > doc/depends.dot
depends.pl *.h > doc/depends.dot
dot -Tps2 -o doc/depends.dot.ps doc/depends.dot
