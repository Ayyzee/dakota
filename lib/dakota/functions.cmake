# -*- mode: cmake -*-
function (dk_join output-var glue) # ...
  set (string "")
  set (_glue "")
  foreach (arg ${ARGN})
    set (string "${string}${_glue}${arg}")
    set (_glue "${glue}")
  endforeach ()
  set (${output-var} "${string}" PARENT_SCOPE)
endfunction ()

function (dk_append_target_property target property) # ...
  get_target_property (current ${target} ${property})
  foreach (arg ${ARGN})
    list (APPEND current ${arg})
  endforeach ()
  dk_join (current-str " " ${current})
  set_target_properties (${target} PROPERTIES ${property} "${current-str}")
endfunction ()

function (dk_install_symlink file symlink)
  install (CODE "execute_process (COMMAND ${CMAKE_COMMAND} -E create_symlink ${file} ${symlink})")
  install (CODE "message (\"-- Installing symlink: ${symlink} -> ${file}\")")
endfunction ()

function (dk_find_lib_files output-var lib-dirs) # ...
  foreach (lib ${ARGN})
    set (found-lib-path NOTFOUND) # found-lib-path-NOTFOUND
    find_library (found-lib-path ${lib} PATHS ${lib-dirs} ${prefix_dir}/lib)
    if (NOT found-lib-path)
      message (FATAL_ERROR "error: target: ${target}: find_library(): ${lib}")
    endif ()
    #message ( "info: target: ${target}: find_library(): ${lib} => ${found-lib-path}")
    list (APPEND lib-paths ${found-lib-path})
  endforeach ()
  set (${output-var} "${lib-paths}" PARENT_SCOPE)
endfunction ()

function (dk_target_lib_files output-var) # ...
  foreach (lib ${ARGN})
    set (target-lib-path ${lib_output_dir}/${lib_prefix}${lib}${lib_suffix})
    list (APPEND target-lib-paths ${target-lib-path})
  endforeach ()
  set (${output-var} "${target-lib-paths}" PARENT_SCOPE)
endfunction ()

function (dk_find_program output-var name)
  set (found-name NOTFOUND)
  find_program (found-name ${name} PATHS ${prefix_dir}/bin)
  if (NOT found-name)
    message (FATAL_ERROR "error: program: ${name}: find_library(): NOTFOUND")
  endif ()
  set (${output-var} "${found-name}" PARENT_SCOPE)
endfunction ()
