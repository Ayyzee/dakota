# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (DEFINED ENV{INSTALL_PREFIX})
    set (CMAKE_INSTALL_PREFIX $ENV{INSTALL_PREFIX})
  else ()
    set (CMAKE_INSTALL_PREFIX /usr/local)
  endif ()
endif()

find_program (cxx-compiler   clang++)
set (dakota-cmake-path   ${CMAKE_CURRENT_SOURCE_DIR}/dakota.cmake)

set (SOURCE_DIR         ${CMAKE_SOURCE_DIR})
set (BINARY_DIR         ${CMAKE_BINARY_DIR})
set (CURRENT_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set (CURRENT_BINARY_DIR ${CMAKE_CURRENT_BINARY_DIR})
set (INSTALL_PREFIX     ${CMAKE_INSTALL_PREFIX})

include (${dakota-cmake-path})

set (project ${target})
project (${project} LANGUAGES CXX)
set (cxx-standard 17)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)
set (CMAKE_LIBRARY_PATH ${CMAKE_INSTALL_PREFIX}/lib)
set (CMAKE_CXX_COMPILER ${cxx-compiler}) # must follow: project (<> LANGUAGES CXX)

set (sanitize-opts -fsanitize=address)
if (${is-lib})
  add_library (${target} SHARED ${srcs})
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
else ()
  add_executable (${target} ${srcs})
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
endif ()

install (FILES ${install-include-files} DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
set_directory_properties (PROPERTY ADDITIONAL_MAKE_CLEAN_FILES ${CMAKE_CURRENT_SOURCE_DIR}/${builddir})
set_source_files_properties (${srcs} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES CXX_VISIBILITY_PRESET hidden)
#set (CMAKE_CXX_VISIBILITY_PRESET hidden)
target_compile_definitions (${target} PRIVATE ${macros})
target_include_directories (${target} PRIVATE ${include-dirs})
target_link_libraries (${target} ${libs})
target_compile_options (${target} PRIVATE
  ${sanitize-opts}
  @${compiler-opts-file}
)
string (CONCAT link-flags
  " ${sanitize-opts}"
)
set_target_properties(${target} PROPERTIES LINK_FLAGS ${link-flags})
