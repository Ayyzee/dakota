#!/bin/bash
set -o errexit -o nounset -o pipefail
binary_dir=$(cat cmake-binary-dir.txt)
if [[ -e Makefile ]]; then make clean || true; fi
if [[ $binary_dir != '.' && $binary_dir != '..' ]]; then
  rm -fr $binary_dir
else
  rm -f  $binary_dir/cmake_install.cmake
  rm -f  $binary_dir/install_manifest.txt
  rm -f  $binary_dir/Makefile
  rm -f  $binary_dir/CMakeCache.txt
  rm -fr $binary_dir/CMakeFiles
fi
