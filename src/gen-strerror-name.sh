#!/bin/bash

set -o nounset

./gen-strerror-name.pl `find /usr/include -name errno.h` > strerror-name.tbl
