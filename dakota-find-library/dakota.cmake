# -*- mode: cmake -*-
set (builddir ${CMAKE_CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts @${root-dir}/lib/dakota/compiler.opts)
set (linker-opts   @${CMAKE_CURRENT_SOURCE_DIR}/../lib/dakota/linker.opts)
set (include-dirs
  ${root-dir}/include
  ${CMAKE_INSTALL_PREFIX}/include
)
set (lib-dirs
  ${root-dir}/lib
  ${CMAKE_INSTALL_PREFIX}/lib
)
set (libs
  dakota-dso
)
set (srcs
  dakota-find-library.cc
)
set (target dakota-find-library)
