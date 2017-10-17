# -*- mode: cmake -*-
include (${prefix_dir}/lib/dakota/base-cxx.cmake)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)
set (cxx-compiler ${CMAKE_CXX_COMPILER})
dk_append_target_property (${target} LINK_FLAGS
  --var=current_source_dir=${CMAKE_CURRENT_SOURCE_DIR}
  --var=cxx=${cxx-compiler})
target_compile_options (${target} PRIVATE
  --var=current_source_dir=${CMAKE_CURRENT_SOURCE_DIR}
  --var=source_dir=${source_dir}
  --var=build_dir=${build_dir}
  --var=cxx=${cxx-compiler})
dk_find_program (CMAKE_CXX_COMPILER dakota${CMAKE_EXECUTABLE_SUFFIX})
dk_find_program (dakota-parts dakota-parts)
dk_find_program (dakota-make dakota-make)

execute_process (
  COMMAND ${dakota-parts} --path-only
    --var=current_source_dir=${CMAKE_CURRENT_SOURCE_DIR}
    --var=source_dir=${source_dir}
    --var=build_dir=${build_dir}
  OUTPUT_VARIABLE parts
  OUTPUT_STRIP_TRAILING_WHITESPACE)

execute_process (
  COMMAND ${dakota-make} --path-only
    --var=current_source_dir=${CMAKE_CURRENT_SOURCE_DIR}
    --var=source_dir=${source_dir}
    --var=build_dir=${build_dir}
  OUTPUT_VARIABLE build-mk
  OUTPUT_STRIP_TRAILING_WHITESPACE)

execute_process (
  COMMAND ${CMAKE_CXX_COMPILER} --action gen-target-src --path-only
    --var=current_source_dir=${CMAKE_CURRENT_SOURCE_DIR}
    --var=source_dir=${source_dir}
    --var=build_dir=${build_dir}
  OUTPUT_VARIABLE target-src
  OUTPUT_STRIP_TRAILING_WHITESPACE)
target_sources (${target} PRIVATE ${target-src})

execute_process (
  COMMAND ${CMAKE_CXX_COMPILER} --action gen-target-hdr --path-only
    --var=current_source_dir=${CMAKE_CURRENT_SOURCE_DIR}
    --var=source_dir=${source_dir}
    --var=build_dir=${build_dir}
  OUTPUT_VARIABLE target-hdr
  OUTPUT_STRIP_TRAILING_WHITESPACE)

file (RELATIVE_PATH rel-target-hdr ${CMAKE_CURRENT_BINARY_DIR} ${target-hdr})

add_custom_command (
  OUTPUT ${parts}
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/build.cmake
  COMMAND ${dakota-parts}
    --var=current_source_dir=${CMAKE_CURRENT_SOURCE_DIR}
    --var=source_dir=${source_dir}
    --var=build_dir=${build_dir}
    ${target-lib-paths}
    ${lib-paths}
  VERBATIM
  USES_TERMINAL)

add_custom_command (
  OUTPUT ${target-src}
  DEPENDS ${parts} ${target-libs} ${custom-target-hdr}
  COMMAND ${CMAKE_CXX_COMPILER} --action gen-target-src
    --var=current_source_dir=${CMAKE_CURRENT_SOURCE_DIR}
    --var=source_dir=${source_dir}
    --var=build_dir=${build_dir}
    --output ${target-src}
  VERBATIM
  USES_TERMINAL)

include (ProcessorCount)
ProcessorCount (processor-count)
set (num-threads-per-core 2)
math (EXPR jobs "${processor-count} / ${num-threads-per-core}")

set (custom-target-hdr ${target}.custom-target-hdr)
# phony target 'custom-target-hdr'
add_custom_target (${custom-target-hdr}
  DEPENDS ${parts} ${target-libs} ${build-mk}
  COMMAND make -s -j ${jobs} -f ${build-mk} ${target-hdr}
  COMMENT "Generating ${rel-target-hdr}"
  VERBATIM
  USES_TERMINAL)
add_dependencies (${target} ${custom-target-hdr})

add_custom_command (
  OUTPUT  ${build-mk}
  DEPENDS ${parts} ${target-libs}
  COMMAND ${dakota-make}
    --var=current_source_dir=${CMAKE_CURRENT_SOURCE_DIR}
    --var=source_dir=${source_dir}
    --var=build_dir=${build_dir}
    --target-path=${target-path}
  VERBATIM
  USES_TERMINAL)
