# -*- mode: cmake -*-
set (macros
)
set (include-dirs
  ${source-dir}/include
)
set (install-include-files
  ${source-dir}/include/dakota-dso.h
)
set (lib-dirs
)
set (libs
  dl
)
set (target-libs
)
set (target-type shared-library)
set (srcs
  ${CMAKE_CURRENT_SOURCE_DIR}/dakota-dso.cc
)
