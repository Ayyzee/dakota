# -*- mode: cmake -*-
set (target dakota-dso)
set (build-dir ${CMAKE_SOURCE_DIR}/build-dkt/${target})
set (compiler-opts @${root-source-dir}/lib/dakota/compiler.opts)
set (linker-opts   @${root-source-dir}/lib/dakota/linker.opts)
set (macros
)
set (include-dirs
  ${root-source-dir}/include
)
set (install-include-files
  ${root-source-dir}/include/dakota-dso.h
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
set (is-lib 1)
set (srcs
  ${CMAKE_CURRENT_SOURCE_DIR}/dakota-dso.cc
)
