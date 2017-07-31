# -*- mode: cmake -*-
set (builddir ${CMAKE_CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts @${root-source-dir}/lib/dakota/compiler.opts)
set (linker-opts   @${CMAKE_CURRENT_SOURCE_DIR}/../lib/dakota/linker.opts)
set (include-dirs
  ${root-source-dir}/include
)
set (install-include-files
  ${root-source-dir}/include/dakota-dso.h
)
set (is-lib 1)
set (libs
  dl
)
set (srcs
  dakota-dso.cc
)
set (target dakota-dso)
