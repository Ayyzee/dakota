# -*- mode: cmake -*-
set (build-dir ${CMAKE_SOURCE_DIR}/build-dkt/${target})
set (macros
)
set (bin-dirs
  ${CMAKE_SOURCE_DIR}/bin
)
set (include-dirs
  ${CMAKE_SOURCE_DIR}/include
)
set (lib-dirs
)
set (libs
)
set (target-lib-dirs
)
set (target-libs
  dakota-dso
  dakota-core
)
set (target-type shared-library)
set (srcs
  ${PROJECT_SOURCE_DIR}/ascii-number-klass.dk
  ${PROJECT_SOURCE_DIR}/ascii-number.dk
  ${PROJECT_SOURCE_DIR}/dakota.dk
  ${PROJECT_SOURCE_DIR}/dimension.dk
  ${PROJECT_SOURCE_DIR}/float.dk
  ${PROJECT_SOURCE_DIR}/hashed-counted-set.dk
  ${PROJECT_SOURCE_DIR}/hashed-set.dk
  ${PROJECT_SOURCE_DIR}/hashed-table.dk
  ${PROJECT_SOURCE_DIR}/input-file.dk
  ${PROJECT_SOURCE_DIR}/json-object-output-stream.dk
  ${PROJECT_SOURCE_DIR}/json-parser.dk
  ${PROJECT_SOURCE_DIR}/lexer.dk
  ${PROJECT_SOURCE_DIR}/open-token.dk
  ${PROJECT_SOURCE_DIR}/output-file.dk
  ${PROJECT_SOURCE_DIR}/point.dk
  ${PROJECT_SOURCE_DIR}/rect.dk
  ${PROJECT_SOURCE_DIR}/slot-info.dk
  ${PROJECT_SOURCE_DIR}/str-buffer.dk
  ${PROJECT_SOURCE_DIR}/syntax-exception.dk
  ${PROJECT_SOURCE_DIR}/text-output-stream.dk
  ${PROJECT_SOURCE_DIR}/token.dk
  ${PROJECT_SOURCE_DIR}/tokenid.dk
  ${PROJECT_SOURCE_DIR}/type-func.dk
  ${PROJECT_SOURCE_DIR}/xml-object-output-stream.dk
)
