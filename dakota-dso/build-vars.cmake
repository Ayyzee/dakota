# -*- mode: cmake -*-
set (macros
)
set (include-dirs
  ${root-dir}/include
)
set (install-include-files
  ${root-dir}/include/dakota-dso.h
)
set (lib-dirs
)
set (libs
  dl
)
set (target-lib-dirs
)
set (target-libs
)
set (target-type shared-library)
set (srcs
  ${PROJECT_SOURCE_DIR}/dakota-dso.cc
)
