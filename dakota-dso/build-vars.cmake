# -*- mode: cmake -*-
set (build-dir ${CMAKE_CURRENT_SOURCE_DIR}/build-dkt)
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
  ${root-source-dir}/lib
)
set (lib-names
  dl
)
set (target-lib-names
)
set (is-lib 1)
set (target dakota-dso)
set (srcs
  ${CMAKE_CURRENT_SOURCE_DIR}/dakota-dso.cc
)
