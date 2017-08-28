# -*- mode: cmake -*-
set (build-dir ${dakota-lang-source-dir}/build-dkt/${target})
set (macros
)
set (bin-dirs
  ${dakota-lang-source-dir}/bin
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
  dakota-core
  dakota
)
set (target-type executable)
set (srcs
  ${PROJECT_SOURCE_DIR}/exe.dk
)
