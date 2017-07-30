# -*- mode: cmake -*-
set (builddir build-dkt)
set (compiler-opts-file ${CURRENT_SOURCE_DIR}/../lib/dakota/compiler.opts)
set (include-dirs
  ${CURRENT_SOURCE_DIR}
  ${CURRENT_SOURCE_DIR}/../include
  ${INSTALL_PREFIX}/include
)
set (lib-dirs
  ${INSTALL_PREFIX}/lib
)
set (libs
  dakota-dso
)
set (srcs
  dakota-catalog.cc
)
set (target dakota-catalog)
