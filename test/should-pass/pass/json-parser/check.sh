#!/bin/sh -u

../../../bin/run-with-timeout 3 ./exe < libdakota.rep > libdakota.perl
./dump.pl < libdakota.perl > libdakota.perl.dump
