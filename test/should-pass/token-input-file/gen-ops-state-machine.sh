#!/bin/sh -u

./gen-ops-state-machine.pl {cpp,cxx,dk}-ops.txt > ops-state-machine.dk
cat ops-state-machine.dk
