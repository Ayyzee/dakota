#!/bin/bash

cat /dev/null > phony-targets.mk
cat /dev/null > /tmp/other-phony-targets.mk
echo "all: \\" > phony-targets.mk
echo "check clean:" >> /tmp/other-phony-targets.mk

exe_src_paths=$(echo should-pass/*/exe.dk)

for exe_src_path in $exe_src_paths; do
    dir=$(dirname $exe_src_path);
    echo " $dir/exe\\" >> phony-targets.mk
    printf "\t\$(MAKE) --directory \$(dir $dir/exe) \$@\n" >> /tmp/other-phony-targets.mk
done
echo >> phony-targets.mk

cat /tmp/other-phony-targets.mk >> phony-targets.mk
