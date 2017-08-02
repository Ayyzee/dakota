# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (DEFINED ENV{INSTALL_PREFIX})
    set (CMAKE_INSTALL_PREFIX $ENV{INSTALL_PREFIX})
  else ()
    set (CMAKE_INSTALL_PREFIX /usr/local)
  endif ()
endif ()

if (NOT root-source-dir)
  set (root-source-dir ${CMAKE_CURRENT_SOURCE_DIR}/..)
endif ()

set (CMAKE_PREFIX_PATH  ${root-source-dir})

find_program (cxx-compiler clang++)
set (build-vars ${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake)

include (${build-vars})

set (cxx-standard 17)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)
#set (CMAKE_LIBRARY_PATH ${root-source-dir}/lib)
set (CMAKE_CXX_COMPILER ${cxx-compiler}) # must follow: project (<> LANGUAGES CXX)

set (found-libs)
foreach (lib ${libs})
  set (found-lib NOTFOUND) # found-lib-NOTFOUND
  find_library (found-lib ${lib} PATHS ${lib-dirs})
  if (NOT found-lib)
    message (FATAL_ERROR "error: target: ${target}: find_library(): ${lib}")
  endif ()
  #message ( "info: target: ${target}: find_library(): ${lib} => ${found-lib}")
  list (APPEND found-libs ${found-lib})
endforeach ()

if (${is-lib})
  add_library (${target} SHARED ${srcs})
  set_target_properties (${target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${root-source-dir}/lib)
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
else ()
  add_executable (${target} ${srcs})
  set_target_properties (${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${root-source-dir}/bin)
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
endif ()

install (FILES ${install-include-files} DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
set_directory_properties (PROPERTY ADDITIONAL_MAKE_CLEAN_FILES ${build-dir})
set_source_files_properties (${srcs} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES CXX_VISIBILITY_PRESET hidden)
#set (CMAKE_CXX_VISIBILITY_PRESET hidden)
target_compile_definitions (${target} PRIVATE ${macros})
target_include_directories (${target} PRIVATE ${include-dirs})
target_link_libraries (${target} ${found-libs})
target_compile_options (${target} PRIVATE
  ${compiler-opts}
)
string (CONCAT link-flags
  " ${linker-opts}"
)
set_target_properties (${target} PROPERTIES LINK_FLAGS ${link-flags})
