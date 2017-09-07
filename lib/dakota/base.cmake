# -*- mode: cmake -*-
include (${prefix-dir}/lib/dakota/base-cxx.cmake)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)
set (cxx-compiler ${CMAKE_CXX_COMPILER})
dk_append_target_property (${target} LINK_FLAGS --var=cxx=${cxx-compiler} --var=build_dir=${CMAKE_CURRENT_BINARY_DIR} --var=source_dir=${CMAKE_CURRENT_SOURCE_DIR})
target_compile_options (   ${target} PRIVATE    --var=cxx=${cxx-compiler} --var=build_dir=${CMAKE_CURRENT_BINARY_DIR} --var=source_dir=${CMAKE_CURRENT_SOURCE_DIR})
dk_find_program (CMAKE_CXX_COMPILER dakota${CMAKE_EXECUTABLE_SUFFIX})
dk_find_program (dakota-parts dakota-parts) # ${CMAKE_EXECUTABLE_SUFFIX}

execute_process (
  COMMAND ${dakota-parts} ${CMAKE_CURRENT_BINARY_DIR} # --path-only
  OUTPUT_VARIABLE parts
  OUTPUT_STRIP_TRAILING_WHITESPACE)

add_custom_command (
  OUTPUT ${parts}
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake
  COMMAND ${dakota-parts} ${CMAKE_CURRENT_BINARY_DIR}
    ${srcs}
    ${target-lib-files}
    ${lib-files}
  VERBATIM)

execute_process (
  COMMAND ${CMAKE_CXX_COMPILER} --target src --path-only --var=build_dir=${CMAKE_CURRENT_BINARY_DIR}
  OUTPUT_VARIABLE target-src
  OUTPUT_STRIP_TRAILING_WHITESPACE)
target_sources (${target} PRIVATE ${target-src})

# generate target-src
add_custom_command (
  OUTPUT ${target-src}
  DEPENDS ${parts} ${target-libs} dakota-catalog${CMAKE_EXECUTABLE_SUFFIX}
  COMMAND ${CMAKE_CXX_COMPILER} --target src --var=build_dir=${CMAKE_CURRENT_BINARY_DIR} --var=source_dir=${CMAKE_CURRENT_SOURCE_DIR}
  VERBATIM)
set (compile-defns DKT_TARGET_FILE="${target-output-file}" DKT_TARGET_TYPE="${target-type}")
set_source_files_properties (${target-src} PROPERTIES COMPILE_DEFINITIONS "${compile-defns}")

set (target-hdr ${target}.target-hdr)
# phony target 'target-hdr'
add_custom_target (
  ${target-hdr}
  DEPENDS ${parts} ${target-libs} dakota-catalog${CMAKE_EXECUTABLE_SUFFIX}
  COMMAND ${CMAKE_CXX_COMPILER} --target hdr --var=build_dir=${CMAKE_CURRENT_BINARY_DIR} --var=source_dir=${CMAKE_CURRENT_SOURCE_DIR}
  VERBATIM)
add_dependencies (${target} ${target-hdr})
