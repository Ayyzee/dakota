# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (DEFINED ENV{INSTALL_PREFIX})
    set (CMAKE_INSTALL_PREFIX $ENV{INSTALL_PREFIX})
  else ()
    set (CMAKE_INSTALL_PREFIX /usr/local)
  endif ()
endif()

set (ENV{PATH} "$ENV{HOME}/dakota/bin:$ENV{PATH}")
find_program (cxx-compiler   clang++)
find_program (dakota         dakota)
find_program (dakota-catalog dakota-catalog)
set (dakota-project-path ${CMAKE_CURRENT_SOURCE_DIR}/dakota.project)
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
set (CMAKE_CXX_COMPILER ${dakota}) # must follow: project (<> LANGUAGES CXX)
#list (APPEND CMAKE_CXX_SOURCE_FILE_EXTENSIONS dk)

set (found-libs)
foreach (lib ${libs})
  set (lib-path lib-path-NOTFOUND)
  find_library (lib-path ${lib})
  # check for error here
  list (APPEND found-libs --found-library=${lib}=${lib-path})
endforeach (lib)

# phony target 'target-ast'
add_custom_target (
  ${target-ast}
  COMMAND ${dakota} --target-ast --project ${dakota-project-path} ${found-libs}
  VERBATIM)
# phony target 'target-hdr'
add_custom_target (
  ${target-hdr}
  DEPENDS ${target-ast}
  COMMAND ${dakota} --target-hdr --project ${dakota-project-path} ${found-libs}
  VERBATIM)
# get target-src path
execute_process (
  COMMAND ${dakota} --target-src --path-only --project ${dakota-project-path}
  OUTPUT_VARIABLE target-src
  OUTPUT_STRIP_TRAILING_WHITESPACE)
# generate target-src
add_custom_command (
  OUTPUT ${target-src}
  COMMAND ${dakota} --target-src --project ${dakota-project-path} ${found-libs}
  VERBATIM)
list (APPEND srcs ${target-src})

set (sanitize-opts -fsanitize=address)
if (${is-lib})
  add_library (${target} SHARED ${srcs})
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
else ()
  add_executable (${target} ${srcs})
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
endif ()
add_dependencies (${target} ${target-hdr})

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
  --project ${dakota-project-path} --cxx ${cxx-compiler} ${found-libs}
  ${sanitize-opts}
  @${compiler-opts-file}
)
string (CONCAT link-flags
  " --project ${dakota-project-path} --cxx ${cxx-compiler}"
  " ${sanitize-opts}"
)
set_target_properties(${target} PROPERTIES LINK_FLAGS ${link-flags})