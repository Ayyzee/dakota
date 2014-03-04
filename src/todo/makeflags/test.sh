#!/bin/sh -u

cmd="make -k"
echo $cmd; eval $cmd; echo

cmd="make -k -n"
echo $cmd; eval $cmd; echo

cmd="make -n"
echo $cmd; eval $cmd; echo

cmd="MAKEFLAGS='-r --warn-undefined-variables' make -j 2 -k -n"
echo $cmd; eval $cmd; echo

cmd="MAKEFLAGS='-k -n' make -j 2 -r"
echo $cmd; eval $cmd; echo

cmd="MAKEFLAGS='-r' make -k"
echo $cmd; eval $cmd; echo

cmd="MAKEFLAGS='-r --warn-undefined-variables' make -k -I /"
echo $cmd; eval $cmd; echo

cmd="MAKEFLAGS='-r -n' make -k"
echo $cmd; eval $cmd; echo

cmd="MAKEFLAGS='--warn-undefined-variables' make -k -I / -B"
echo $cmd; eval $cmd; echo

cmd="MAKEFLAGS='-r -B' make -k -I / -B"
echo $cmd; eval $cmd; echo

cmd="MAKEFLAGS='-r -R' make -B -k -I /"
echo $cmd; eval $cmd; echo

cmd="MAKEFLAGS='-r -R' make -B -k -I / -l 0.7"
echo $cmd; eval $cmd; echo
