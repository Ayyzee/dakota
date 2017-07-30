# -*- mode: cmake -*-
set (builddir ${CMAKE_CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts-file ${CMAKE_CURRENT_SOURCE_DIR}/../lib/dakota/compiler.opts)
set (include-dirs
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}/../include
  ${CMAKE_INSTALL_PREFIX}/include
)
set (lib-dirs
  ${CMAKE_INSTALL_PREFIX}/lib
)
set (libs
  dakota-dso
)
set (srcs
  dakota-catalog.cc
)
set (target dakota-catalog)
