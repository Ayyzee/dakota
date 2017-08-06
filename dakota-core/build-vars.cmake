# -*- mode: cmake -*-
set (target dakota-core)
set (build-dir ${CMAKE_SOURCE_DIR}/build-dkt/${target})
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
set (lib-dirs
)
set (lib-names
)
set (target-lib-dirs
)
set (target-lib-names
  dakota-dso
)
set (is-lib 1)
set (srcs
  ${CMAKE_CURRENT_SOURCE_DIR}/bit-vector.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/boole.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/char.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/collection.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/compare.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/const-info.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/core.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/counted-set.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/dakota-core.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/deque.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/item-already-present-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/enum-info.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/hash.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/illegal-klass-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/input-stream.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/int.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/iterator.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/keyword-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/keyword.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/klass.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/method-alias.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/method.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/missing-keyword-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/named-enum-info.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/named-info.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/no-such-keyword-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/no-such-method-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/no-such-slot-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/number.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/object-input-stream.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/object-output-stream.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/object.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/output-stream.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/pair.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/property.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/ptr.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/result.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/selector-node.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/selector.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/sequence.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/set-of-pairs.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/set.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/signal-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/signature.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/singleton-klass.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/size.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/sorted-counted-set.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/sorted-set-core.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/sorted-set.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/sorted-table.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/stack.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/std-compare.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/str.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/str128.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/str256.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/str32.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/str512.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/str64.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/stream.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/string.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/super.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/symbol.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/system-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/table.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/trace.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/unbox-illegal-klass-exception.dk
  ${CMAKE_CURRENT_SOURCE_DIR}/vector.dk
)
