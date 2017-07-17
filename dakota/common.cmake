# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
set (dakota dakota)
set (dk-cxx-compiler clang++)
set (project-path ${CMAKE_SOURCE_DIR}/dakota.project)

string (REGEX REPLACE "\.project$" ".cmake" vars-path ${project-path})
# generate vars-path
execute_process (
  COMMAND dakota-build2cmake ${project-path} ${vars-path}
)
include (${vars-path})

set (project ${target})
project (${project} LANGUAGES CXX)
set (cxx-standard 17)
set (CMAKE_CXX_COMPILER dk) # must follow: project (<> LANGUAGES CXX)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)
# unfortunately quotes are required because we appending to CMAKE_CXX_FLAGS
list (APPEND CMAKE_CXX_FLAGS "--project ${project-path} --cxx ${dk-cxx-compiler}")

include_directories (${include-dirs})

set (link-libs)
set (found-libs)
foreach (lib ${libs})
  set (lib-path lib-path-NOTFOUND)
  find_library (lib-path ${lib})
  list (APPEND link-libs ${lib-path})
  list (APPEND found-libs --found-library ${lib}=${lib-path})
endforeach (lib)

# phony target 'init'
add_custom_target (
  init
  COMMAND ${dakota} --project ${project-path} --init ${found-libs}
  VERBATIM)
# get target-cc path
execute_process (
  COMMAND ${dakota} --project ${project-path} --target --path-only
  OUTPUT_VARIABLE target-src
  OUTPUT_STRIP_TRAILING_WHITESPACE)
# generate target-cc
add_custom_command (
  OUTPUT ${target-src}
  COMMAND ${dakota} --project ${project-path} --target
  VERBATIM)
list (APPEND srcs ${target-src})

set_directory_properties (PROPERTY ADDITIONAL_MAKE_CLEAN_FILES ${builddir})
set_source_files_properties (${srcs} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})

if (${is-lib})
  add_library (${target} SHARED ${srcs})
  set (targets-install-dir ${CMAKE_INSTALL_PREFIX}/lib)
else ()
  add_executable (${target} ${srcs})
  set (targets-install-dir ${CMAKE_INSTALL_PREFIX}/bin)
endif ()

install (TARGETS ${target} DESTINATION ${targets-install-dir})
target_compile_definitions (${target} PRIVATE ${macros})
target_compile_options (${target} PRIVATE --warn-no-multichar) # unfortunate
set_target_properties (${target} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
target_link_libraries (${target} ${link-libs})
