# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
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
set (CMAKE_CXX_COMPILER clang++) # must follow: project (<> LANGUAGES CXX)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)

include_directories (${include-dirs})

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
