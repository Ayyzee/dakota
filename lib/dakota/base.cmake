# -*- mode: cmake -*-
include (${prefix-dir}/lib/dakota/base-cxx.cmake)
set (parts ${current-build-dir}/parts.yaml)
include (${prefix-dir}/lib/dakota/compiler.cmake)
dk_find_program (dakota-parts dakota-parts) # ${CMAKE_EXECUTABLE_SUFFIX}

execute_process (
  COMMAND ${CMAKE_CXX_COMPILER} --target-src --parts ${parts} --path-only
  OUTPUT_VARIABLE target-src
  OUTPUT_STRIP_TRAILING_WHITESPACE)
target_sources (${target} PRIVATE ${target-src})

set (target-hdr ${target}.target-hdr)
# phony target 'target-hdr'
add_custom_target (
  ${target-hdr}
  DEPENDS ${parts} ${target-libs} dakota-catalog${CMAKE_EXECUTABLE_SUFFIX}
  COMMAND ${CMAKE_CXX_COMPILER} --target-hdr --parts ${parts}
  VERBATIM)
add_dependencies (${target} ${target-hdr})

# generate parts.yaml
add_custom_command (
  OUTPUT ${parts}
  COMMAND ${dakota-parts} ${parts}
    source-dir: ${CMAKE_CURRENT_SOURCE_DIR}
    lib-files:  ${target-lib-files} ${lib-files}
    srcs:       ${srcs}
  VERBATIM)

# generate target-src
add_custom_command (
  OUTPUT ${target-src}
  DEPENDS ${parts} ${target-libs} dakota-catalog${CMAKE_EXECUTABLE_SUFFIX}
  COMMAND ${CMAKE_CXX_COMPILER} --target-src --parts ${parts}
  VERBATIM)
set (compile-defns DKT_TARGET_FILE="${target-output-file}" DKT_TARGET_TYPE="${target-type}")
set_source_files_properties (${target-src} PROPERTIES COMPILE_DEFINITIONS "${compile-defns}")
