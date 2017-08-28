# -*- mode: cmake -*-
set (build-dir ${dakota-lang-source-dir}/build-dkt/${target})
set (macros
)
set (include-dirs
  ${dakota-lang-source-dir}/include
)
set (install-include-files
  ${dakota-lang-source-dir}/include/dakota-dso.h
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
