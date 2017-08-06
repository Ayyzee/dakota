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

set (cxx-standard 17)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)
#set (CMAKE_LIBRARY_PATH ${root-source-dir}/lib)
find_program (cxx-compiler clang++)
set (CMAKE_CXX_COMPILER ${cxx-compiler})

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
set (additional-make-clean-files
  ${build-dir}
)
set_directory_properties (PROPERTY ADDITIONAL_MAKE_CLEAN_FILES "${additional-make-clean-files}")
set_source_files_properties (${srcs} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES CXX_VISIBILITY_PRESET hidden)
#set (CMAKE_CXX_VISIBILITY_PRESET hidden)
target_compile_definitions (${target} PRIVATE ${macros})
target_include_directories (${target} PRIVATE ${include-dirs})
target_compile_options (${target} PRIVATE
  ${compiler-opts}
)
string (CONCAT link-flags
  " ${linker-opts}"
)
set_target_properties (${target} PROPERTIES LINK_FLAGS ${link-flags})
target_link_libraries (${target} ${libs})
