#!/bin/sh -u

if [ -e /usr/bin/true ]; then
bin_true=/usr/bin/true
bin_false=/usr/bin/false
else
bin_true=/bin/true
bin_false=/bin/false
fi

./distexec $bin_true &
./distexec $bin_false &

./distexec $bin_true &
./distexec $bin_false &

./distexec $bin_true &
./distexec $bin_false &
