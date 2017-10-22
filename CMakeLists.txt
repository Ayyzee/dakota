# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (dakota-lang-project LANGUAGES CXX)

set (source_dir ${${PROJECT_NAME}_SOURCE_DIR})
set (build_dir  ${${PROJECT_NAME}_BINARY_DIR})
set (prefix_dir ${${PROJECT_NAME}_SOURCE_DIR})

set (lib_dir ${prefix_dir}/lib)
set (bin_dir ${prefix_dir}/bin)

include (${lib_dir}/dakota/platform.cmake)

add_subdirectory (dakota-dso)
add_subdirectory (dakota-catalog)
add_subdirectory (dakota-find-library)
add_subdirectory (dakota-core)
add_subdirectory (dakota)
add_subdirectory (tst1)
add_subdirectory (tst2)

enable_testing ()
add_test (NAME tst1 COMMAND ${source_dir}/tst1/exe)
add_test (NAME tst2 COMMAND ${source_dir}/tst2/exe)
