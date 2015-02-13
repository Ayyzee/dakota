#!/bin/bash

echo $@:

exe_src_paths=$(echo should-pass/*/exe.dk)

for exe_src_path in $exe_src_paths; do
    dir=$(dirname $exe_src_path);
    printf "\t\$(MAKE) --directory \$(dir $dir/exe) \$@\n"
done
