# -*- mode: cmake -*-
set (builddir build-dkt)
set (include-dirs
  ${SOURCE_DIR}/../include
)
set (install-include-files
  ${SOURCE_DIR}/../include/dakota-dso.h
)
set (is-lib 1)
set (libs
  dl
)
set (srcs
  dakota-dso.cc
)
set (target dakota-dso)
set (warn-opts-file ../warn.opts)
