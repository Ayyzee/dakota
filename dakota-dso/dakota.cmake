# -*- mode: cmake -*-
set (builddir ${CMAKE_CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts-file ${CMAKE_CURRENT_SOURCE_DIR}/../lib/dakota/compiler.opts)
set (include-dirs
  ${CMAKE_CURRENT_SOURCE_DIR}/../include
)
set (install-include-files
  ${CMAKE_CURRENT_SOURCE_DIR}/../include/dakota-dso.h
)
set (is-lib 1)
set (libs
  dl
)
set (srcs
  dakota-dso.cc
)
set (target dakota-dso)
