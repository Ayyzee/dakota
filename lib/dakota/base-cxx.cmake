# -*- mode: cmake -*-
set (CMAKE_VERBOSE_MAKEFILE $ENV{CMAKE_VERBOSE_MAKEFILE})
set (CMAKE_PREFIX_PATH ${prefix-dir})

function (join output-var glue) # ...
  set (string "")
  set (_glue "")
  foreach (arg ${ARGN})
    set (string "${string}${_glue}${arg}")
    set (_glue "${glue}")
  endforeach ()
  set (${output-var} "${string}" PARENT_SCOPE)
endfunction ()

function (append_target_property target property) # ...
  get_target_property (current ${target} ${property})
  foreach (arg ${ARGN})
    list (APPEND current ${arg})
  endforeach ()
  join (current-str " " ${current})
  set_target_properties (${target} PROPERTIES ${property} "${current-str}")
endfunction ()

function (install_symlink file symlink)
  install (CODE "execute_process (COMMAND ${CMAKE_COMMAND} -E create_symlink ${file} ${symlink})")
  install (CODE "message (\"-- Installing symlink: ${symlink} -> ${file}\")")
endfunction ()

function (find_lib_files output-var lib-dirs) # ...
  foreach (lib ${ARGN})
    set (found-lib-file NOTFOUND) # found-lib-file-NOTFOUND
    find_library (found-lib-file ${lib} PATHS ${lib-dirs})
    if (NOT found-lib-file)
      message (FATAL_ERROR "error: target: ${target}: find_library(): ${lib}")
    endif ()
    #message ( "info: target: ${target}: find_library(): ${lib} => ${found-lib-file}")
    list (APPEND lib-files ${found-lib-file})
  endforeach ()
  set (${output-var} "${lib-files}" PARENT_SCOPE)
endfunction ()

function (find_target_lib_files output-var) # ...
  foreach (lib ${ARGN})
    set (target-lib-file ${prefix-dir}/lib/${CMAKE_SHARED_LIBRARY_PREFIX}${lib}${CMAKE_SHARED_LIBRARY_SUFFIX})
    list (APPEND target-lib-files ${target-lib-file})
  endforeach ()
  set (${output-var} "${target-lib-files}" PARENT_SCOPE)
endfunction ()

function (dk_find_program output-var name)
  set (found-name NOTFOUND)
  find_program (found-name ${name})
  if (NOT found-name)
    message (FATAL_ERROR "error: program: ${name}: find_library(): NOTFOUND")
  endif ()
  set (${output-var} "${found-name}" PARENT_SCOPE)
endfunction ()

# current-build-dir is set to be a filesystem peer of current-binary-dir
# (this implies build-dir and binary-dir have the same relationship)
function (current_build_dir output-var current-binary-dir)
  get_filename_component (current-binary-dir-dir  ${current-binary-dir} DIRECTORY)
  get_filename_component (current-binary-dir-name ${current-binary-dir} NAME)
  set (build-dir ${current-binary-dir-dir}/../dkt)
  get_filename_component (build-dir ${build-dir} REALPATH)
  set (current-build-dir ${build-dir}/${current-binary-dir-name})
  set (${output-var} "${current-build-dir}" PARENT_SCOPE)
endfunction ()

current_build_dir (current-build-dir ${CMAKE_CURRENT_BINARY_DIR})
if (DEFINED use-binary-dir-as-build-dir OR DEFINED ENV{DKT_USE_BINARY_DIR_AS_BUILD_DIR})
  set (current-build-dir ${CMAKE_CURRENT_BINARY_DIR})
endif ()

if (NOT target-type)
  set (target-type executable)
endif ()

if (${target-type} STREQUAL shared-library)
  add_library (${target} SHARED ${srcs})
  set_target_properties (${target} PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${prefix-dir}/lib)
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

find_lib_files (lib-files "${lib-dirs}" ${libs})
find_target_lib_files (target-lib-files ${target-libs})

set (compiler-opts @${prefix-dir}/lib/dakota/compiler.opts)
set (linker-opts   @${prefix-dir}/lib/dakota/linker.opts)
target_compile_options (${target} PRIVATE ${compiler-opts})
set (link-options ${linker-opts})
join (link-options-str " " ${link-options})
set_target_properties (${target} PROPERTIES LINK_FLAGS "${link-options-str}")
#set (CMAKE_LIBRARY_PATH ${prefix-dir}/lib)
set (cxx-standard 17)
set (CMAKE_COMPILER_IS_GNUCXX TRUE)
dk_find_program (cxx-compiler clang++${CMAKE_EXECUTABLE_SUFFIX})
set (CMAKE_CXX_COMPILER ${cxx-compiler})
install (FILES ${install-include-files} DESTINATION ${CMAKE_INSTALL_PREFIX}/include)
set (additional-make-clean-files
  ${current-build-dir}
)
set_directory_properties (PROPERTY ADDITIONAL_MAKE_CLEAN_FILES "${additional-make-clean-files}")
set_source_files_properties (${srcs} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES CXX_VISIBILITY_PRESET hidden)
#set (CMAKE_CXX_VISIBILITY_PRESET hidden)
target_compile_definitions (${target} PRIVATE ${macros})
target_include_directories (${target} PRIVATE ${include-dirs})
list (LENGTH lib-files lib-files-count)
if (${lib-files-count})
  target_link_libraries (${target} ${lib-files})
endif ()
list (LENGTH target-lib-files target-lib-files-count)
if (${target-lib-files-count})
  target_link_libraries (${target} ${target-lib-files})
  add_dependencies (     ${target} ${target-libs})
endif ()
