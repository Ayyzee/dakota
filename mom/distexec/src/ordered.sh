#!/bin/sh -u

if [ ! -e cmd-echo ]; then
    echo "missing cmd-echo"
    exit 1
fi

./distexec ./cmd-echo 0 &
./distexec ./cmd-echo 1 &
./distexec ./cmd-echo 2 &
./distexec ./cmd-echo 3 &
./distexec ./cmd-echo 4 &
./distexec ./cmd-echo 5 &
./distexec ./cmd-echo 6 &
./distexec ./cmd-echo 7 &
./distexec ./cmd-echo 8 &
./distexec ./cmd-echo 9 &
