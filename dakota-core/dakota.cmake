# -*- mode: cmake -*-
set (builddir ${CURRENT_SOURCE_DIR}/build-dkt)
set (compiler-opts-file ${CURRENT_SOURCE_DIR}/../lib/dakota/compiler.opts)
set (include-dirs
  ${CURRENT_SOURCE_DIR}
  ${CURRENT_SOURCE_DIR}/../include
  ${INSTALL_PREFIX}/include
)
set (is-lib 1)
set (lib-dirs
  ${INSTALL_PREFIX}/lib
)
set (libs
  dakota-dso
)
set (macros
)
set (srcs
  ${CURRENT_SOURCE_DIR}/bit-vector.dk
  ${CURRENT_SOURCE_DIR}/boole.dk
  ${CURRENT_SOURCE_DIR}/char.dk
  ${CURRENT_SOURCE_DIR}/collection.dk
  ${CURRENT_SOURCE_DIR}/compare.dk
  ${CURRENT_SOURCE_DIR}/const-info.dk
  ${CURRENT_SOURCE_DIR}/core.dk
  ${CURRENT_SOURCE_DIR}/counted-set.dk
  ${CURRENT_SOURCE_DIR}/dakota-core.dk
  ${CURRENT_SOURCE_DIR}/deque.dk
  ${CURRENT_SOURCE_DIR}/item-already-present-exception.dk
  ${CURRENT_SOURCE_DIR}/enum-info.dk
  ${CURRENT_SOURCE_DIR}/exception.dk
  ${CURRENT_SOURCE_DIR}/hash.dk
  ${CURRENT_SOURCE_DIR}/illegal-klass-exception.dk
  ${CURRENT_SOURCE_DIR}/input-stream.dk
  ${CURRENT_SOURCE_DIR}/int.dk
  ${CURRENT_SOURCE_DIR}/iterator.dk
  ${CURRENT_SOURCE_DIR}/keyword-exception.dk
  ${CURRENT_SOURCE_DIR}/keyword.dk
  ${CURRENT_SOURCE_DIR}/klass.dk
  ${CURRENT_SOURCE_DIR}/method-alias.dk
  ${CURRENT_SOURCE_DIR}/method.dk
  ${CURRENT_SOURCE_DIR}/missing-keyword-exception.dk
  ${CURRENT_SOURCE_DIR}/named-enum-info.dk
  ${CURRENT_SOURCE_DIR}/named-info.dk
  ${CURRENT_SOURCE_DIR}/no-such-keyword-exception.dk
  ${CURRENT_SOURCE_DIR}/no-such-method-exception.dk
  ${CURRENT_SOURCE_DIR}/no-such-slot-exception.dk
  ${CURRENT_SOURCE_DIR}/number.dk
  ${CURRENT_SOURCE_DIR}/object-input-stream.dk
  ${CURRENT_SOURCE_DIR}/object-output-stream.dk
  ${CURRENT_SOURCE_DIR}/object.dk
  ${CURRENT_SOURCE_DIR}/output-stream.dk
  ${CURRENT_SOURCE_DIR}/pair.dk
  ${CURRENT_SOURCE_DIR}/property.dk
  ${CURRENT_SOURCE_DIR}/ptr.dk
  ${CURRENT_SOURCE_DIR}/result.dk
  ${CURRENT_SOURCE_DIR}/selector-node.dk
  ${CURRENT_SOURCE_DIR}/selector.dk
  ${CURRENT_SOURCE_DIR}/sequence.dk
  ${CURRENT_SOURCE_DIR}/set-of-pairs.dk
  ${CURRENT_SOURCE_DIR}/set.dk
  ${CURRENT_SOURCE_DIR}/signal-exception.dk
  ${CURRENT_SOURCE_DIR}/signature.dk
  ${CURRENT_SOURCE_DIR}/singleton-klass.dk
  ${CURRENT_SOURCE_DIR}/size.dk
  ${CURRENT_SOURCE_DIR}/sorted-counted-set.dk
  ${CURRENT_SOURCE_DIR}/sorted-set-core.dk
  ${CURRENT_SOURCE_DIR}/sorted-set.dk
  ${CURRENT_SOURCE_DIR}/sorted-table.dk
  ${CURRENT_SOURCE_DIR}/stack.dk
  ${CURRENT_SOURCE_DIR}/std-compare.dk
  ${CURRENT_SOURCE_DIR}/str.dk
  ${CURRENT_SOURCE_DIR}/str128.dk
  ${CURRENT_SOURCE_DIR}/str256.dk
  ${CURRENT_SOURCE_DIR}/str32.dk
  ${CURRENT_SOURCE_DIR}/str512.dk
  ${CURRENT_SOURCE_DIR}/str64.dk
  ${CURRENT_SOURCE_DIR}/stream.dk
  ${CURRENT_SOURCE_DIR}/string.dk
  ${CURRENT_SOURCE_DIR}/super.dk
  ${CURRENT_SOURCE_DIR}/symbol.dk
  ${CURRENT_SOURCE_DIR}/system-exception.dk
  ${CURRENT_SOURCE_DIR}/table.dk
  ${CURRENT_SOURCE_DIR}/trace.dk
  ${CURRENT_SOURCE_DIR}/unbox-illegal-klass-exception.dk
  ${CURRENT_SOURCE_DIR}/vector.dk
)
set (target dakota-core)
