# -*- mode: cmake -*-
set (dakota-project2cmake dakota-project2cmake)
set (dakota               dakota)
set (root-dir ${CMAKE_SOURCE_DIR}/..)
set (ENV{PATH} "${root-dir}/bin:$ENV{PATH}")
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
set (project-path ${CMAKE_SOURCE_DIR}/dakota.project)

string (REGEX REPLACE "\.project$" ".cmake" vars-path ${project-path})
# generate vars-path
execute_process (
  COMMAND ${dakota-project2cmake} ${project-path} ${vars-path}
)
include (${vars-path})
include (${root-dir}/warn.cmake)

set (project ${target})
project (${project} LANGUAGES CXX)
set (cxx-standard 17)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)

set (CMAKE_CXX_COMPILER ${dakota}) # must follow: project (<> LANGUAGES CXX)
set (cxx-compiler clang++)
set (CMAKE_CXX_VISIBILITY_PRESET hidden)
# unfortunately quotes are required because we appending to CMAKE_CXX_FLAGS
list (APPEND CMAKE_CXX_FLAGS "--project ${project-path} --cxx ${cxx-compiler}")
set (found-libs)
foreach (lib ${libs})
  set (lib-path lib-path-NOTFOUND)
  find_library (lib-path ${lib})
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

include_directories (${include-dirs})
install (TARGETS ${target} DESTINATION ${targets-install-dir})
install (FILES ${install-include-files} DESTINATION /usr/local/include)
target_compile_definitions (${target} PRIVATE ${macros})
target_compile_options (${target} PRIVATE ${cxx-compiler-warning-flags})
set_target_properties (${target} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
target_link_libraries (${target} ${libs})
