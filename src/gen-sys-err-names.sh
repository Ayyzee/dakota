#!/bin/bash

set -o nounset

./gen-sys-err-names.pl `find /usr/include -name errno.h` > sys-err-names.tbl
