set (builddir dkt)
set (include-dirs
  ../include
  ${INSTALL_PREFIX}/include
)
set (is-lib 1)
set (lib-dirs
  ${INSTALL_PREFIX}/lib
)
set (libs
  dso
  dakota-core
)
set (macros
)
set (srcs
  ascii-number-klass.dk
  ascii-number.dk
  dakota.dk
  dimension.dk
  float.dk
  hashed-counted-set.dk
  hashed-set.dk
  hashed-table.dk
  input-file.dk
  json-object-output-stream.dk
  json-parser.dk
  lexer.dk
  open-token.dk
  output-file.dk
  point.dk
  rect.dk
  slot-info.dk
  str-buffer.dk
  syntax-exception.dk
  text-output-stream.dk
  token.dk
  tokenid.dk
  type-func.dk
  xml-object-output-stream.dk
)
set (target dakota)
