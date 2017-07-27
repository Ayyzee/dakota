#!/bin/bash
set -o errexit -o nounset -o pipefail
INSTALL_PREFIX=$HOME/opt
if [[ $# == 1 ]]; then
  INSTALL_PREFIX=$1
fi
rm -f $INSTALL_PREFIX/include/dakota*
rm -f $INSTALL_PREFIX/lib/libdakota*
rm -f $INSTALL_PREFIX/lib/dakota/*
rm -f $INSTALL_PREFIX/bin/dakota*
