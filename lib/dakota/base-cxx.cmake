# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
include (${prefix-dir}/lib/dakota/functions.cmake)

if (NOT target-type)
  set (target-type executable)
endif ()

if (${target-type} STREQUAL shared-library)
  add_library (${target} SHARED ${srcs})
  set_target_properties (${target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${prefix-dir}/lib)
  install (FILES ${install-include-files} DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
  set (target-output-file ${CMAKE_SHARED_LIBRARY_PREFIX}${target}${CMAKE_SHARED_LIBRARY_SUFFIX})
elseif (${target-type} STREQUAL executable)
  add_executable (${target} ${srcs})
  set_target_properties (${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${prefix-dir}/bin)
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
  set (target-output-file ${target}${CMAKE_EXECUTABLE_SUFFIX})
else ()
  message (FATAL_ERROR "error: target-type must be shared-library or executable.")
endif ()

dk_find_lib_files (lib-files "${lib-dirs}" ${libs}) # PATHS ...
dk_target_lib_files (target-lib-files ${target-libs})

target_link_libraries (${target} ${lib-files})
target_link_libraries (${target} ${target-lib-files})
if (DEFINED target-libs)
  add_dependencies (   ${target} ${target-libs})
endif ()

include (${prefix-dir}/lib/dakota/compiler-cxx.cmake)
