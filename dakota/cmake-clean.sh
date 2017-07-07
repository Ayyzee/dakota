#!/bin/bash
set -o errexit -o nounset -o pipefail

builddir=dkt

if [[ -e Makefile ]]; then make clean || true; fi
rm -f  cmake_install.cmake
rm -f  install_manifest.txt
rm -f  Makefile
rm -f  CMakeCache.txt
rm -fr CMakeFiles
rm -f  dakota.cmk
rm -f  dakota.project
rm -fr $builddir # created by dakota
rm -fr build
