# -*- mode: cmake -*-
set (target dakota-catalog)
set (build-dir ${CMAKE_SOURCE_DIR}/build-dkt/${target})
set (compiler-opts @${root-source-dir}/lib/dakota/compiler.opts)
set (linker-opts   @${root-source-dir}/lib/dakota/linker.opts)
set (macros
)
set (include-dirs
  ${root-source-dir}/include
)
set (lib-dirs
)
set (lib-names
)
set (target-lib-dirs
)
set (target-lib-names
  dakota-dso
)
set (srcs
  ${CMAKE_CURRENT_SOURCE_DIR}/dakota-catalog.cc
)
