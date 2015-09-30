#!/bin/bash

set -o nounset -o pipefail

dirs="\
 should-pass/pass/add-method-on-object\
 should-pass/pass/add-method-on-string\
"

if [[ $# > 0 ]]; then
  dirs=$(echo $@ | sort)
fi

basename=$(basename $0)
rm -f $basename-pass.txt
rm -f $basename-fail.txt
touch $basename-pass.txt
touch $basename-fail.txt
exit_val=0

for dir in $dirs; do
  echo "### \"$dir/\""
  make --directory $dir clean
  make $dir/exe
  make --directory $dir check
  exe_exit_val=$?
  if [[ 0 == $exe_exit_val ]]; then
    echo "$basename: PASS: $exe_exit_val $dir" >> $basename-pass.txt
  else
    echo "$basename: FAIL: $exe_exit_val $dir" >> $basename-fail.txt
    exit_val=1
  fi
done

echo
cat $basename-pass.txt
echo
cat $basename-fail.txt
#rm -f $basename-pass.txt
#rm -f $basename-fail.txt
exit $exit_val
