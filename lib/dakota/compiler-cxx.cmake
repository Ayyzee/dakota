# -*- mode: cmake -*-
set (cxx-standard 17)
set (compiler-opts-path @${prefix_dir}/lib/dakota/compiler.opts) # specific to gcc/clang
set (linker-opts-path   @${prefix_dir}/lib/dakota/linker.opts)   # specific to gcc/clang
dk_join (linker-opts-path-str " " ${linker-opts-path})

set_source_files_properties (${srcs}  PROPERTIES LANGUAGE              CXX
                                                 CXX_STANDARD          ${cxx-standard})
set_target_properties (     ${target} PROPERTIES LANGUAGE              CXX
                                                 CXX_STANDARD          ${cxx-standard}
                                                 CXX_VISIBILITY_PRESET hidden
                                                 LINK_FLAGS            "${linker-opts-path-str}")
target_compile_options (    ${target} PRIVATE ${compiler-opts-path})
target_compile_definitions (${target} PRIVATE ${macros})
target_include_directories (${target} PRIVATE ${include-dirs})
