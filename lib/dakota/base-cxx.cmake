# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
include (${prefix_dir}/lib/dakota/functions.cmake)

if (NOT target-type)
  set (target-type executable)
endif ()

get_filename_component (output_dir  ${output_path} DIRECTORY)
get_filename_component (output_name ${output_path} NAME)

if (${target-type} STREQUAL shared-library)
  add_library (${target} SHARED ${srcs})
  set_target_properties (${target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${output_dir})
  install (FILES ${install-include-files} DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
  set (target-output-path ${lib_output_dir}/${CMAKE_SHARED_LIBRARY_PREFIX}${target}${CMAKE_SHARED_LIBRARY_SUFFIX})
elseif (${target-type} STREQUAL executable)
  add_executable (${target} ${srcs})
  set_target_properties (${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${output_dir})
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
  set (target-output-path ${runtime-output-directory}/${target}${CMAKE_EXECUTABLE_SUFFIX})
else ()
  message (FATAL_ERROR "error: target-type must be shared-library or executable.")
endif ()
set_target_properties (${target} PROPERTIES OUTPUT_NAME ${output_name})

dk_find_lib_files (lib-files "${lib-dirs}" ${libs}) # PATHS ...
dk_target_lib_files (target-lib-files ${target-libs})

target_link_libraries (${target} ${lib-files})
target_link_libraries (${target} ${target-lib-files})
if (DEFINED target-libs)
  add_dependencies (   ${target} ${target-libs})
endif ()

include (${prefix_dir}/lib/dakota/compiler-cxx.cmake)
