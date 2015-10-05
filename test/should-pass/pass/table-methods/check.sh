#!/bin/sh -u

../../../bin/run-with-timeout 3 ./exe $@ | c++filt | ./check-methods.pl
