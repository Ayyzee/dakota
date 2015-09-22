#!/bin/sh

if [[ ! -e include-dirs.txt ]]; then
    find / -name Volumes -prune -o -name "include" -type d > include-dirs.txt
fi

include_dirs=$(cat include-dirs.txt)

if [[ ! -e memory-files.txt ]]; then
    touch memory-files.txt
    for include_dir in $include_dirs; do
        find $include_dir -name "memory" -type d >> memory-files.txt
    done
fi

memory_files=$(cat memory-files.txt)
#echo memory-files: $memory_files

grep -l "class shared_ptr" $memory_files
