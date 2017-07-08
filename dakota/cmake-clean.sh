#!/bin/bash
set -o errexit -o nounset -o pipefail

dir=$(cat cmake-build-dir.txt)
builddir=dkt

if [[ -e Makefile ]]; then make clean || true; fi
rm -f  $dir/cmake_install.cmake
rm -f  $dir/install_manifest.txt
rm -f  $dir/Makefile
rm -f  $dir/CMakeCache.txt
rm -fr $dir/CMakeFiles
rm -f  $dir/dakota.cmk
rm -f  $dir/dakota.project
rm -fr $builddir # created by dakota
