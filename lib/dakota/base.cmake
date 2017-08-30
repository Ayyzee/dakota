# -*- mode: cmake -*-
get_target_property(link-flags ${target} LINK_FLAGS)
set (parts ${build-dir}/parts.yaml)
list (APPEND link-flags
  --parts ${parts} --cxx ${cxx-compiler})
opts_str ("${link-flags}" link-flags-str)
set_target_properties (${target} PROPERTIES LINK_FLAGS "${link-flags-str}")
set (dakota NOTFOUND) # dakota-NOTFOUND
find_program (dakota dakota${CMAKE_EXECUTABLE_SUFFIX} PATHS ${bin-dirs})
if (NOT dakota)
  message (FATAL_ERROR "error: program: dakota: find_library(): ${dakota}")
endif ()
get_filename_component (dakota-dir ${dakota} DIRECTORY)

set (CMAKE_CXX_COMPILER ${dakota})
execute_process (
  COMMAND ${dakota-dir}/dakota-parts ${parts}
    source-dir:         ${dakota-lang-source-dir}
    project-source-dir: ${PROJECT_SOURCE_DIR}
    build-dir:          ${build-dir}
    lib-files:          ${target-lib-files} ${lib-files}
    srcs:               ${srcs})
add_custom_command (
  OUTPUT ${parts}
  COMMAND ${dakota-dir}/dakota-parts ${parts}
    source-dir:         ${dakota-lang-source-dir}
    project-source-dir: ${PROJECT_SOURCE_DIR}
    build-dir:          ${build-dir}
    lib-files:          ${target-lib-files} ${lib-files}
    srcs:               ${srcs}
  VERBATIM)
execute_process (
  COMMAND ${dakota} --target-src --parts ${parts} --path-only
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
# generate target-src
add_custom_command (
  OUTPUT ${target-src}
  DEPENDS ${parts} ${target-libs} dakota-catalog${CMAKE_EXECUTABLE_SUFFIX}
  COMMAND ${dakota} --target-src --parts ${parts}
  VERBATIM)
add_dependencies (${target} ${target-hdr})
target_compile_options (${target} PRIVATE
  --parts ${parts} --cxx ${cxx-compiler})

set (compile-defns DKT_TARGET_FILE="${target-output-file}" DKT_TARGET_TYPE="${target-type}")
set_source_files_properties (${target-src} PROPERTIES COMPILE_DEFINITIONS "${compile-defns}")
