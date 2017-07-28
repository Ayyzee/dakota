# -*- mode: cmake -*-
set (root-dir ${CMAKE_SOURCE_DIR}/..)
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (DEFINED ENV{INSTALL_PREFIX})
    set (CMAKE_INSTALL_PREFIX $ENV{INSTALL_PREFIX})
  else ()
    set (CMAKE_INSTALL_PREFIX /usr/local)
  endif ()
endif()

set (SOURCE_DIR     ${CMAKE_SOURCE_DIR})
set (BINARY_DIR     ${CMAKE_BINARY_DIR})
set (INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})

include (${CMAKE_SOURCE_DIR}/dakota.cmake)
#include (${root-dir}/compiler.cmake)

set (project ${target})
project (${project} LANGUAGES CXX)
set (cxx-standard 17)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)
set (CMAKE_LIBRARY_PATH ${CMAKE_INSTALL_PREFIX}/lib)
set (CMAKE_CXX_COMPILER clang++) # must follow: project (<> LANGUAGES CXX)

set (sanitize-opts -fsanitize=address)
if (${is-lib})
  add_library (${target} SHARED ${srcs})
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
else ()
  add_executable (${target} ${srcs})
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
endif ()

install (FILES ${install-include-files} DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
set_directory_properties (PROPERTY ADDITIONAL_MAKE_CLEAN_FILES ${builddir})
set_source_files_properties (${srcs} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES CXX_VISIBILITY_PRESET hidden)
#set (CMAKE_CXX_VISIBILITY_PRESET hidden)
target_compile_definitions (${target} PRIVATE ${macros})
target_include_directories (${target} PRIVATE ${include-dirs})
target_link_libraries (${target} ${libs})
target_compile_options (${target} PRIVATE
  ${sanitize-opts}
  @${CMAKE_SOURCE_DIR}/${compiler-opts-file}
)
string (CONCAT link-flags
  " ${sanitize-opts}"
)
set_target_properties(${target} PROPERTIES LINK_FLAGS ${link-flags})
