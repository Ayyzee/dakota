# -*- mode: cmake -*-
set (cxx-compiler ${CMAKE_CXX_COMPILER})
set (cxx-standard 17)
set (compiler-opts-file @${prefix-dir}/lib/dakota/compiler.opts)
set (linker-opts-file   @${prefix-dir}/lib/dakota/linker.opts)
dk_join (linker-opts-file-str " " ${linker-opts-file})

set_source_files_properties (${srcs}  PROPERTIES LANGUAGE              CXX
                                                 CXX_STANDARD          ${cxx-standard})
set_target_properties (     ${target} PROPERTIES LANGUAGE              CXX
                                                 CXX_STANDARD          ${cxx-standard}
                                                 CXX_VISIBILITY_PRESET hidden
                                                 LINK_FLAGS            "${linker-opts-file-str}")
target_compile_options (    ${target} PRIVATE ${compiler-opts-file})
target_compile_definitions (${target} PRIVATE ${macros})
target_include_directories (${target} PRIVATE ${include-dirs})
