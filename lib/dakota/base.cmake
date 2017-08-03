# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (DEFINED ENV{INSTALL_PREFIX})
    set (CMAKE_INSTALL_PREFIX $ENV{INSTALL_PREFIX})
  else ()
    set (CMAKE_INSTALL_PREFIX /usr/local)
  endif ()
endif ()

set (CMAKE_PREFIX_PATH  ${root-source-dir})

set (cxx-standard 17)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)
#set (CMAKE_LIBRARY_PATH ${root-source-dir}/lib)
find_program (cxx-compiler clang++)
find_program (dakota       dakota PATHS ${bin-dirs})
set (parts ${CMAKE_CURRENT_SOURCE_DIR}/parts.yaml)
set (CMAKE_CXX_COMPILER ${dakota})
file (WRITE ${parts} "build-dir: ${build-dir}") # dummy ${parts} created here

# get target-src path
execute_process (
  COMMAND ${dakota} --target-src --parts ${parts} --path-only # dummy ${parts}
  OUTPUT_VARIABLE target-src
  OUTPUT_STRIP_TRAILING_WHITESPACE)

set (libs)
foreach (lib-name ${lib-names})
  set (lib NOTFOUND) # lib-NOTFOUND
  find_library (lib ${lib-name} PATHS ${lib-dirs})
  if (NOT lib)
    message (FATAL_ERROR "error: target: ${target}: find_library(): ${lib-name}")
  endif ()
  #message ( "info: target: ${target}: find_library(): ${lib} => ${lib-name}")
  list (APPEND libs ${lib})
endforeach ()

set (target-libs)
foreach (lib-name ${target-lib-names})
  set (target-lib ${root-source-dir}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}${lib-name}${CMAKE_SHARED_LIBRARY_SUFFIX})
  list (APPEND target-libs ${target-lib})
endforeach ()

if (NOT is-lib)
  set (is-lib 0)
endif ()

# phony target 'parts-yaml'
add_custom_target (
  ${parts-yaml}
  COMMAND ${root-source-dir}/bin/dakota-parts.sh ${parts}
    target:    ${target}
    is-lib:    ${is-lib}
    build-dir: ${build-dir}
    libs:      ${target-libs}      ${libs}
    srcs:      ${srcs}
  VERBATIM)
# phony target 'target-ast'
add_custom_target (
  ${target-ast}
  DEPENDS ${parts-yaml} ${target-lib-names} dakota-catalog
  COMMAND ${dakota} --target-ast --parts ${parts}
  VERBATIM)
# phony target 'target-hdr'
add_custom_target (
  ${target-hdr}
  DEPENDS ${target-ast}
  COMMAND ${dakota} --target-hdr --parts ${parts}
  VERBATIM)
# generate target-src
add_custom_command (
  OUTPUT ${target-src}
  DEPENDS ${target-ast}
  COMMAND ${dakota} --target-src --parts ${parts}
  VERBATIM)
list (APPEND srcs ${target-src})

if (${is-lib})
  add_library (${target} SHARED ${srcs})
  set_target_properties (${target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${root-source-dir}/lib)
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
else ()
  add_executable (${target} ${srcs})
  set_target_properties (${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${root-source-dir}/bin)
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
endif ()
add_dependencies (${target} ${target-hdr})

install (FILES ${install-include-files} DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
set (additional-make-clean-files
  ${build-dir}
  ${parts}
)
set_directory_properties (PROPERTY ADDITIONAL_MAKE_CLEAN_FILES "${additional-make-clean-files}")
set_source_files_properties (${srcs} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES CXX_VISIBILITY_PRESET hidden)
#set (CMAKE_CXX_VISIBILITY_PRESET hidden)
target_compile_definitions (${target} PRIVATE ${macros})
target_include_directories (${target} PRIVATE ${include-dirs})
target_link_libraries (${target} ${libs})
target_compile_options (${target} PRIVATE
  --parts ${parts} --cxx ${cxx-compiler}
  ${compiler-opts}
)
string (CONCAT link-flags
  " --parts ${parts} --cxx ${cxx-compiler}"
  " ${linker-opts}"
)
set_target_properties (${target} PROPERTIES LINK_FLAGS ${link-flags})
