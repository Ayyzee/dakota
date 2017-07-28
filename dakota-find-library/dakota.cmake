# -*- mode: cmake -*-
set (builddir build-dkt)
set (compiler-opts-file ../lib/dakota/compiler.opts)
set (include-dirs
  ${SOURCE_DIR}/../include
  ${INSTALL_PREFIX}/include
)
set (lib-dirs
  ${INSTALL_PREFIX}/lib
)
set (libs
  dakota-dso
)
set (srcs
  dakota-find-library.cc
)
set (target dakota-find-library)
