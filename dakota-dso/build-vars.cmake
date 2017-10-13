# -*- mode: cmake -*-
set (macros
)
set (include-dirs
  ${source_dir}/include
)
set (install-include-files
  ${source_dir}/include/dakota-dso.h
)
set (lib-dirs
)
set (libs
  dl
)
set (target-libs
)
set (target dakota-dso)
set (target-type shared-library)
set (srcs
  dakota-dso.cc
)
