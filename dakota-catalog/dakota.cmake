# -*- mode: cmake -*-
set (builddir ${CMAKE_CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts @${root-source-dir}/lib/dakota/compiler.opts)
set (linker-opts   @${CMAKE_CURRENT_SOURCE_DIR}/../lib/dakota/linker.opts)
set (include-dirs
  ${root-source-dir}/include
  ${CMAKE_INSTALL_PREFIX}/include
)
set (lib-dirs
  ${root-source-dir}/lib
  ${CMAKE_INSTALL_PREFIX}/lib
)
set (libs
  dakota-dso
)
set (srcs
  dakota-catalog.cc
)
set (target dakota-catalog)
