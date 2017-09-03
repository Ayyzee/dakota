# -*- mode: cmake -*-
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

function (target_lib_files output-var) # ...
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
