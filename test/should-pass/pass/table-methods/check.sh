#!/bin/sh -u

./exe $@ | c++filt | ./check-methods.pl
