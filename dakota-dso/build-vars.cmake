# -*- mode: cmake -*-
set (build-dir ${CMAKE_SOURCE_DIR}/build-dkt/${target})
set (macros
)
set (include-dirs
  ${CMAKE_SOURCE_DIR}/include
)
set (install-include-files
  ${CMAKE_SOURCE_DIR}/include/dakota-dso.h
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
  ${CMAKE_CURRENT_SOURCE_DIR}/dakota-dso.cc
)
