# -*- mode: cmake -*-
set (builddir build-dkt)
set (compiler-opts-file ${CURRENT_SOURCE_DIR}/../lib/dakota/compiler.opts)
set (include-dirs
  ${CURRENT_SOURCE_DIR}/../include
)
set (install-include-files
  ${CURRENT_SOURCE_DIR}/../include/dakota-dso.h
)
set (is-lib 1)
set (libs
  dl
)
set (srcs
  dakota-dso.cc
)
set (target dakota-dso)
