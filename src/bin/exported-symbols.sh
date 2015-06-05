#!/bin/sh -u

nm -g lib/libdakota.$so_ext | grep -v " U " | grep -v __gmp | c++filt | grep -v \\.eh | grep -v " typeinfo "
