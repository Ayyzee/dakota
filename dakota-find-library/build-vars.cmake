# -*- mode: cmake -*-
set (build-dir ${CMAKE_CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts @${root-source-dir}/lib/dakota/compiler.opts)
set (linker-opts   @${root-source-dir}/lib/dakota/linker.opts)
set (include-dirs
  ${root-source-dir}/include
)
set (lib-dirs
  ${root-source-dir}/lib
)
set (libs
)
set (target-libs
  dakota-dso
)
set (srcs
  ${CMAKE_CURRENT_SOURCE_DIR}/dakota-find-library.cc
)
set (target dakota-find-library)
