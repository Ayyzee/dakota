# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
include (${prefix_dir}/lib/dakota/functions.cmake)

if (NOT target-type)
  set (target-type executable)
endif ()

get_filename_component (target-output-dir  ${target-output-path} DIRECTORY)
get_filename_component (target-output-name ${target-output-path} NAME)

if (${target-type} STREQUAL shared-library)
  add_library (${target} SHARED ${srcs})
  set_target_properties (${target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${target-output-dir})
  install (FILES ${install-include-files} DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
elseif (${target-type} STREQUAL executable)
  add_executable (${target} ${srcs})
  set_target_properties (${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${target-output-dir})
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
else ()
  message (FATAL_ERROR "error: target-type must be shared-library or executable.")
endif ()
set_target_properties (${target} PROPERTIES OUTPUT_NAME ${target-output-name})

dk_find_lib_files (lib-files "${lib-dirs}" ${libs}) # PATHS ...
dk_target_lib_files (target-lib-files ${target-libs})

target_link_libraries (${target} ${lib-files})
target_link_libraries (${target} ${target-lib-files})
if (DEFINED target-libs)
  add_dependencies (   ${target} ${target-libs})
endif ()

include (${prefix_dir}/lib/dakota/compiler-cxx.cmake)
