# -*- mode: cmake -*-
set (builddir ${CMAKE_CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts @${root-source-dir}/lib/dakota/compiler.opts)
set (linker-opts   @${root-source-dir}/lib/dakota/linker.opts)
set (macros
)
set (bin-dirs
  ${root-source-dir}/bin
)
set (include-dirs
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${root-source-dir}/include
)
set (is-lib 1)
set (lib-dirs
  ${root-source-dir}/lib
)
set (libs
  dakota-dso
  dakota-core
)
set (target dakota)
set (srcs
  ${CMAKE_CURRENT_SOURCE_DIR}/ascii-number-klass.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/ascii-number.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/dakota.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/dimension.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/float.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/hashed-counted-set.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/hashed-set.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/hashed-table.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/input-file.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/json-object-output-stream.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/json-parser.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/lexer.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/open-token.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/output-file.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/point.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/rect.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/slot-info.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/str-buffer.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/syntax-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/text-output-stream.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/token.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/tokenid.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/type-func.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/xml-object-output-stream.dk
)
