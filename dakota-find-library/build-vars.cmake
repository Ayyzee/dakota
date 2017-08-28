# -*- mode: cmake -*-
set (build-dir ${dakota-lang-source-dir}/build-dkt/${target})
set (macros
)
set (include-dirs
  ${dakota-lang-source-dir}/include
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
  ${PROJECT_SOURCE_DIR}/dakota-find-library.cc
)
