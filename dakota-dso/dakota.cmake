# -*- mode: cmake -*-
set (builddir ${CMAKE_CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts-file ${root-dir}/lib/dakota/compiler.opts)
set (include-dirs
  ${root-dir}/include
)
set (install-include-files
  ${root-dir}/include/dakota-dso.h
)
set (is-lib 1)
set (libs
  dl
)
set (srcs
  dakota-dso.cc
)
set (target dakota-dso)
