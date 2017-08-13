# -*- mode: cmake -*-
set (build-dir ${CMAKE_SOURCE_DIR}/build-dkt/${target})
set (macros
)
set (include-dirs
  ${CMAKE_SOURCE_DIR}/include
)
set (lib-dirs
)
set (libs
)
set (target-lib-dirs
)
set (target-libs
  dakota-dso
)
set (srcs
  ${PROJECT_SOURCE_DIR}/dakota-catalog.cc
)
