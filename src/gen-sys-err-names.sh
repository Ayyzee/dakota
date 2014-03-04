#!/bin/sh -u

./gen-sys-err-names.pl `find /usr/include -name errno.h` > sys-err-names.tbl
