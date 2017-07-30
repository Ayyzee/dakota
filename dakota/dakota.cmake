# -*- mode: cmake -*-
set (builddir ${CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts-file ${CURRENT_SOURCE_DIR}/../lib/dakota/compiler.opts)
set (include-dirs
  ${CURRENT_SOURCE_DIR}/../include
  ${INSTALL_PREFIX}/include
)
set (is-lib 1)
set (lib-dirs
  ${INSTALL_PREFIX}/lib
)
set (libs
  dakota-dso
  dakota-core
)
set (macros
)
set (srcs
  ${CURRENT_SOURCE_DIR}/ascii-number-klass.dk
  ${CURRENT_SOURCE_DIR}/ascii-number.dk
  ${CURRENT_SOURCE_DIR}/dakota.dk
  ${CURRENT_SOURCE_DIR}/dimension.dk
  ${CURRENT_SOURCE_DIR}/float.dk
  ${CURRENT_SOURCE_DIR}/hashed-counted-set.dk
  ${CURRENT_SOURCE_DIR}/hashed-set.dk
  ${CURRENT_SOURCE_DIR}/hashed-table.dk
  ${CURRENT_SOURCE_DIR}/input-file.dk
  ${CURRENT_SOURCE_DIR}/json-object-output-stream.dk
  ${CURRENT_SOURCE_DIR}/json-parser.dk
  ${CURRENT_SOURCE_DIR}/lexer.dk
  ${CURRENT_SOURCE_DIR}/open-token.dk
  ${CURRENT_SOURCE_DIR}/output-file.dk
  ${CURRENT_SOURCE_DIR}/point.dk
  ${CURRENT_SOURCE_DIR}/rect.dk
  ${CURRENT_SOURCE_DIR}/slot-info.dk
  ${CURRENT_SOURCE_DIR}/str-buffer.dk
  ${CURRENT_SOURCE_DIR}/syntax-exception.dk
  ${CURRENT_SOURCE_DIR}/text-output-stream.dk
  ${CURRENT_SOURCE_DIR}/token.dk
  ${CURRENT_SOURCE_DIR}/tokenid.dk
  ${CURRENT_SOURCE_DIR}/type-func.dk
  ${CURRENT_SOURCE_DIR}/xml-object-output-stream.dk
)
set (target dakota)
