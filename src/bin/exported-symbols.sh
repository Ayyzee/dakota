#!/bin/sh -u

nm -g lib/libdakota.$SO_EXT | grep -v " U " | grep -v __gmp | c++filt | grep -v \\.eh | grep -v " typeinfo "
