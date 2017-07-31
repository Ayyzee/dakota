#!/bin/bash
set -o nounset -o errexit -o pipefail

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

source $DIR/common.sh

install_prefix=/usr/local
if [[ $# == 1 ]]; then
  install_prefix=$1
fi

sysname=$(platform)
compiler=$(compiler)

echo $sysname
echo $compiler
exit

source $DIR/config-$sysname.sh

canon_compiler=$(compiler $compiler)
pushd $install_prefix/lib/dakota
$LN $LNFLAGS linker-$canon_compiler.opts    linker.opts
$LN $LNFLAGS compiler-$canon_compiler.opts  compiler.opts
$LN $LNFLAGS compiler-$canon_compiler.cmake compiler.cmake
$LN $LNFLAGS compiler-command-line-$canon_compiler.json compiler-command-line.json
$LN $LNFLAGS platform-$sysname.json   platform.json
popd
