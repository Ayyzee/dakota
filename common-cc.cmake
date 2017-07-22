# -*- mode: cmake -*-
set (dakota-build2project dakota-build2project)
set (dakota-build2cmake   dakota-build2cmake)
set (dakota               dakota)
set (root-dir ${CMAKE_SOURCE_DIR}/..)
set (ENV{PATH} "${root-dir}/bin:$ENV{PATH}")
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
set (dakota-build-path ${CMAKE_SOURCE_DIR}/dakota.build)

string (REGEX REPLACE "\.build$" ".project" dakota-project-path ${dakota-build-path})
string (REGEX REPLACE "\.build$" ".cmake"   dakota-cmake-path   ${dakota-build-path})
# generate dakota-cmake-path
execute_process (
  COMMAND ${dakota-build2project} ${dakota-build-path} ${dakota-project-path}
  COMMAND ${dakota-build2cmake}   ${dakota-build-path} ${dakota-cmake-path}
)
set (SOURCE_DIR     ${CMAKE_SOURCE_DIR})
set (BINARY_DIR     ${CMAKE_BINARY_DIR})
set (INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})

include (${dakota-cmake-path})
include (${root-dir}/warn.cmake)

set (project ${target})
project (${project} LANGUAGES CXX)
set (cxx-standard 17)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)

set (CMAKE_CXX_COMPILER clang++) # must follow: project (<> LANGUAGES CXX)
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
