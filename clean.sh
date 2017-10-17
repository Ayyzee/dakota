#!/bin/bash
set -o errexit -o nounset -o pipefail
lib_prefix=lib
lib_suffix='.dylib'
exe_suffix=
source_dir=/Users/robert/dakota
rm -f bin/dakota-catalog$exe_suffix bin/dakota-find-library$exe_suffix
rm -f lib/${lib_prefix}dakota-dso$lib_suffix lib/${lib_prefix}dakota-core$lib_suffix lib/${lib_prefix}dakota$lib_suffix
rm -f bin/exe-core$exe_suffix bin/exe$exe_suffix
rm -fr $source_dir/zzz
