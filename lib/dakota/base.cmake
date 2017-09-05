# -*- mode: cmake -*-
include (${prefix-dir}/lib/dakota/base-cxx.cmake)
set (parts ${current-build-dir}/parts.txt) # invariant
set (CMAKE_COMPILER_IS_GNUCXX TRUE)
set (cxx-compiler ${CMAKE_CXX_COMPILER})
dk_append_target_property (${target} LINK_FLAGS --cxx ${cxx-compiler} --parts ${parts} --var=source_dir=${CMAKE_CURRENT_SOURCE_DIR} --var=build_dir=${current-build-dir})
target_compile_options (   ${target} PRIVATE    --cxx ${cxx-compiler} --parts ${parts} --var=source_dir=${CMAKE_CURRENT_SOURCE_DIR} --var=build_dir=${current-build-dir})
dk_find_program (CMAKE_CXX_COMPILER dakota${CMAKE_EXECUTABLE_SUFFIX})
dk_find_program (dakota-parts dakota-parts) # ${CMAKE_EXECUTABLE_SUFFIX}

execute_process (
  COMMAND ${CMAKE_CXX_COMPILER} --target-src --path-only --parts ${parts} --var=source_dir=${CMAKE_CURRENT_SOURCE_DIR} --var=build_dir=${current-build-dir}
  OUTPUT_VARIABLE target-src
  OUTPUT_STRIP_TRAILING_WHITESPACE)
target_sources (${target} PRIVATE ${target-src})

# generate target-src
add_custom_command (
  OUTPUT ${target-src}
  COMMAND ${CMAKE_CXX_COMPILER} --target-src --parts ${parts} --var=source_dir=${CMAKE_CURRENT_SOURCE_DIR} --var=build_dir=${current-build-dir}
  DEPENDS ${parts} ${target-libs} dakota-catalog${CMAKE_EXECUTABLE_SUFFIX}
  VERBATIM)
set (compile-defns DKT_TARGET_FILE="${target-output-file}" DKT_TARGET_TYPE="${target-type}")
set_source_files_properties (${target-src} PROPERTIES COMPILE_DEFINITIONS "${compile-defns}")

set (target-hdr ${target}.target-hdr)
# phony target 'target-hdr'
add_custom_target (
  ${target-hdr}
  DEPENDS ${parts} ${target-libs} dakota-catalog${CMAKE_EXECUTABLE_SUFFIX}
  COMMAND ${CMAKE_CXX_COMPILER} --target-hdr --parts ${parts} --var=source_dir=${CMAKE_CURRENT_SOURCE_DIR} --var=build_dir=${current-build-dir}
  VERBATIM)
add_dependencies (${target} ${target-hdr})

# generate parts.txt
add_custom_command (
  OUTPUT ${parts}
  COMMAND ${dakota-parts} ${parts}
    ${srcs}
    ${target-lib-files}
    ${lib-files}
  VERBATIM)
