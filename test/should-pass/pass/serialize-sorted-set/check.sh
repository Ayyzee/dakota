#!/bin/sh -u

./exe > out.pl
./dump.pl < out.pl > out-dumped.pl
