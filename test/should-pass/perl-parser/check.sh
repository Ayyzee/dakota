#!/bin/sh -u

./exe < libdakota.rep > libdakota.perl
./dump.pl < libdakota.perl > libdakota.perl.dump
