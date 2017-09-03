# -*- mode: cmake -*-
dk_append_target_property (${target} LINK_FLAGS --parts ${parts} --cxx ${cxx-compiler})
target_compile_options (${target} PRIVATE    --parts ${parts} --cxx ${cxx-compiler})
dk_find_program (dakota dakota${CMAKE_EXECUTABLE_SUFFIX})
set (CMAKE_CXX_COMPILER ${dakota})
