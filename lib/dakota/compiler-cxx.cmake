# -*- mode: cmake -*-
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
set_source_files_properties (${srcs} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES LANGUAGE CXX CXX_STANDARD ${cxx-standard})
set_target_properties (${target} PROPERTIES CXX_VISIBILITY_PRESET hidden)
#set (CMAKE_CXX_VISIBILITY_PRESET hidden)
target_compile_definitions (${target} PRIVATE ${macros})
target_include_directories (${target} PRIVATE ${include-dirs})
