#!/bin/sh -u

cmd=$@

./distexec $cmd &
./distexec $cmd &
./distexec $cmd &
./distexec $cmd &
./distexec $cmd &
