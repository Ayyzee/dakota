# -*- mode: cmake -*-
set (build-dir ${CMAKE_CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts @${root-source-dir}/lib/dakota/compiler.opts)
set (linker-opts   @${root-source-dir}/lib/dakota/linker.opts)
set (macros
)
set (include-dirs
  ${root-source-dir}/include
)
set (lib-dirs
  ${root-source-dir}/lib
)
set (lib-names
)
set (target-lib-names
  dakota-dso
)
set (target dakota-catalog)
set (srcs
  ${CMAKE_CURRENT_SOURCE_DIR}/dakota-catalog.cc
)
