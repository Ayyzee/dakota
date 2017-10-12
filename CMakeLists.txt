# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (dakota-lang-project LANGUAGES CXX)

set (source_dir ${${PROJECT_NAME}_SOURCE_DIR})
set (build_dir  ${${PROJECT_NAME}_BINARY_DIR})
set (prefix_dir ${${PROJECT_NAME}_SOURCE_DIR})

add_subdirectory (dakota-dso)
add_subdirectory (dakota-catalog)
add_subdirectory (dakota-core)
add_subdirectory (dakota)
add_subdirectory (exe-core)
add_subdirectory (exe)

enable_testing ()
add_test (NAME exe-core COMMAND exe-core)
add_test (NAME exe      COMMAND exe)
