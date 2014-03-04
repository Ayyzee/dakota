#!/bin/sh -u

grep -L "module " *.dk
echo
svn status `grep -L "module " *.dk`
