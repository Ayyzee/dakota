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
