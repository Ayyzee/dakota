#!/bin/sh -u

../../../bin/run-with-timeout 3 ./exe > out.pl
./dump.pl < out.pl > out-dumped.pl
