# -*- mode: cmake -*-
set (parts ${current-build-dir}/parts.yaml)
append_target_property (${target} LINK_FLAGS "--parts ${parts} --cxx ${cxx-compiler}")
target_compile_options (${target} PRIVATE --parts ${parts} --cxx ${cxx-compiler})
dk_find_program (dakota dakota${CMAKE_EXECUTABLE_SUFFIX})
get_filename_component (dakota-dir ${dakota} DIRECTORY)
set (CMAKE_CXX_COMPILER ${dakota})
execute_process (
  COMMAND ${dakota} --target-src --path-only ${current-build-dir}
  OUTPUT_VARIABLE target-src
  OUTPUT_STRIP_TRAILING_WHITESPACE)
target_sources (${target} PRIVATE ${target-src})
set (target-hdr ${target}.target-hdr)
# phony target 'target-hdr'
add_custom_target (
  ${target-hdr}
  DEPENDS ${parts} ${target-libs} dakota-catalog${CMAKE_EXECUTABLE_SUFFIX}
  COMMAND ${dakota} --target-hdr --parts ${parts}
  VERBATIM)
# generate parts.yaml
add_custom_command (
  OUTPUT ${parts}
  COMMAND ${dakota-dir}/dakota-parts ${parts}
    source-dir:         ${CMAKE_CURRENT_SOURCE_DIR}
    build-dir:          ${current-build-dir}
    lib-files:          ${target-lib-files} ${lib-files}
    srcs:               ${srcs}
  VERBATIM)
# generate target-src
add_custom_command (
  OUTPUT ${target-src}
  DEPENDS ${parts} ${target-libs} dakota-catalog${CMAKE_EXECUTABLE_SUFFIX}
  COMMAND ${dakota} --target-src --parts ${parts}
  VERBATIM)
add_dependencies (${target} ${target-hdr})
set (compile-defns DKT_TARGET_FILE="${target-output-file}" DKT_TARGET_TYPE="${target-type}")
set_source_files_properties (${target-src} PROPERTIES COMPILE_DEFINITIONS "${compile-defns}")
