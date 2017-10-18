# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
include (${prefix_dir}/lib/dakota/functions.cmake)

if (NOT target-type)
  set (target-type executable)
endif ()

get_filename_component (target-dir  ${target-path} DIRECTORY)
get_filename_component (target-name ${target-path} NAME) # libxxx.so (not xxx)

if (${target-type} STREQUAL shared-library)
  add_library (${target} SHARED ${srcs})
  set_target_properties (${target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${target-dir})
  set_target_properties (${target} PROPERTIES PREFIX "") # target-name already has leading 'lib'
  set_target_properties (${target} PROPERTIES SUFFIX "") # target-name already has trailing '.so'
  install (FILES ${install-include-files} DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/lib)
elseif (${target-type} STREQUAL executable)
  add_executable (${target} ${srcs})
  set_target_properties (${target} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${target-dir})
  set_target_properties (${target} PROPERTIES SUFFIX "") # target-name already has trailing '.exe' (on win64)
  install (TARGETS ${target} DESTINATION ${CMAKE_INSTALL_PREFIX}/bin)
else ()
  message (FATAL_ERROR "error: target-type must be shared-library or executable.")
endif ()
set_target_properties (${target} PROPERTIES OUTPUT_NAME ${target-name}) # aaa.exe or libxxx.so (not aaa nor xxx)

dk_find_lib_files (lib-files "${lib-dirs}" ${libs}) # PATHS ...
dk_target_lib_paths (target-lib-paths ${target-libs})

target_link_libraries (${target} ${lib-files})
target_link_libraries (${target} ${target-lib-paths})
if (DEFINED target-libs)
  add_dependencies (   ${target} ${target-libs})
endif ()

include (${prefix_dir}/lib/dakota/compiler-cxx.cmake)
