# -*- mode: cmake -*-
set (macros
)
set (bin-dirs
  ${root-source-dir}/bin
)
set (include-dirs
  ${root-source-dir}/include
)
set (lib-dirs
)
set (libs
)
set (target-libs
  dakota-core
  dakota
)
set (target-type executable)
set (srcs
  ${CMAKE_CURRENT_SOURCE_DIR}/exe.dk
)
