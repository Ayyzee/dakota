#!/bin/bash

cat /dev/null > /tmp/phony-targets.mk
echo "all check clean:" >> /tmp/phony-targets.mk

exe_src_paths=$(echo should-pass/*/exe.dk)

for exe_src_path in $exe_src_paths; do
    dir=$(dirname $exe_src_path);
    printf "\t\$(MAKE) --directory \$(dir $dir/exe) \$@\n" >> /tmp/phony-targets.mk
done

mv /tmp/phony-targets.mk phony-targets.mk
