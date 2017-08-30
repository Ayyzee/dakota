# -*- mode: cmake -*-
set (build-dir ${source-dir}/build-dkt/${target})
set (macros
)
set (bin-dirs
  ${source-dir}/bin
)
set (include-dirs
  ${PROJECT_SOURCE_DIR}
  ${source-dir}/include
)
set (lib-dirs
)
set (libs
)
set (target-lib-dirs
)
set (target-libs
  dakota-dso
)
set (target-type shared-library)
set (srcs
  ${PROJECT_SOURCE_DIR}/bit-vector.dk
  ${PROJECT_SOURCE_DIR}/boole.dk
  ${PROJECT_SOURCE_DIR}/char.dk
  ${PROJECT_SOURCE_DIR}/collection.dk
  ${PROJECT_SOURCE_DIR}/compare.dk
  ${PROJECT_SOURCE_DIR}/const-info.dk
  ${PROJECT_SOURCE_DIR}/core.dk
  ${PROJECT_SOURCE_DIR}/counted-set.dk
  ${PROJECT_SOURCE_DIR}/dakota-core.dk
  ${PROJECT_SOURCE_DIR}/deque.dk
  ${PROJECT_SOURCE_DIR}/item-already-present-exception.dk
  ${PROJECT_SOURCE_DIR}/enum-info.dk
  ${PROJECT_SOURCE_DIR}/exception.dk
  ${PROJECT_SOURCE_DIR}/hash.dk
  ${PROJECT_SOURCE_DIR}/illegal-klass-exception.dk
  ${PROJECT_SOURCE_DIR}/input-stream.dk
  ${PROJECT_SOURCE_DIR}/int.dk
  ${PROJECT_SOURCE_DIR}/iterator.dk
  ${PROJECT_SOURCE_DIR}/keyword-exception.dk
  ${PROJECT_SOURCE_DIR}/keyword.dk
  ${PROJECT_SOURCE_DIR}/klass.dk
  ${PROJECT_SOURCE_DIR}/method-alias.dk
  ${PROJECT_SOURCE_DIR}/method.dk
  ${PROJECT_SOURCE_DIR}/missing-keyword-exception.dk
  ${PROJECT_SOURCE_DIR}/named-enum-info.dk
  ${PROJECT_SOURCE_DIR}/named-info.dk
  ${PROJECT_SOURCE_DIR}/no-such-keyword-exception.dk
  ${PROJECT_SOURCE_DIR}/no-such-method-exception.dk
  ${PROJECT_SOURCE_DIR}/no-such-slot-exception.dk
  ${PROJECT_SOURCE_DIR}/number.dk
  ${PROJECT_SOURCE_DIR}/object-input-stream.dk
  ${PROJECT_SOURCE_DIR}/object-output-stream.dk
  ${PROJECT_SOURCE_DIR}/object.dk
  ${PROJECT_SOURCE_DIR}/output-stream.dk
  ${PROJECT_SOURCE_DIR}/pair.dk
  ${PROJECT_SOURCE_DIR}/property.dk
  ${PROJECT_SOURCE_DIR}/ptr.dk
  ${PROJECT_SOURCE_DIR}/result.dk
  ${PROJECT_SOURCE_DIR}/selector-node.dk
  ${PROJECT_SOURCE_DIR}/selector.dk
  ${PROJECT_SOURCE_DIR}/sequence.dk
  ${PROJECT_SOURCE_DIR}/set-of-pairs.dk
  ${PROJECT_SOURCE_DIR}/set.dk
  ${PROJECT_SOURCE_DIR}/signal-exception.dk
  ${PROJECT_SOURCE_DIR}/signature.dk
  ${PROJECT_SOURCE_DIR}/singleton-klass.dk
  ${PROJECT_SOURCE_DIR}/size.dk
  ${PROJECT_SOURCE_DIR}/sorted-counted-set.dk
  ${PROJECT_SOURCE_DIR}/sorted-set-core.dk
  ${PROJECT_SOURCE_DIR}/sorted-set.dk
  ${PROJECT_SOURCE_DIR}/sorted-table.dk
  ${PROJECT_SOURCE_DIR}/stack.dk
  ${PROJECT_SOURCE_DIR}/std-compare.dk
  ${PROJECT_SOURCE_DIR}/str.dk
  ${PROJECT_SOURCE_DIR}/str128.dk
  ${PROJECT_SOURCE_DIR}/str256.dk
  ${PROJECT_SOURCE_DIR}/str32.dk
  ${PROJECT_SOURCE_DIR}/str512.dk
  ${PROJECT_SOURCE_DIR}/str64.dk
  ${PROJECT_SOURCE_DIR}/stream.dk
  ${PROJECT_SOURCE_DIR}/string.dk
  ${PROJECT_SOURCE_DIR}/super.dk
  ${PROJECT_SOURCE_DIR}/symbol.dk
  ${PROJECT_SOURCE_DIR}/system-exception.dk
  ${PROJECT_SOURCE_DIR}/table.dk
  ${PROJECT_SOURCE_DIR}/trace.dk
  ${PROJECT_SOURCE_DIR}/unbox-illegal-klass-exception.dk
  ${PROJECT_SOURCE_DIR}/vector.dk
)
