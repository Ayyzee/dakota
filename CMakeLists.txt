# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)

project (dk)

set (root-dir ${CMAKE_SOURCE_DIR})

set (CMAKE_PREFIX_PATH  ${root-dir})

set (CMAKE_INCLUDE_PATH ${root-dir}/include)
set (CMAKE_LIBRARY_PATH ${root-dir}/lib)
set (CMAKE_PROGRAM_PATH ${root-dir}/bin)

add_subdirectory (dakota-dso)
add_subdirectory (dakota-catalog)
add_subdirectory (dakota-core)
add_subdirectory (dakota)

add_dependencies (dakota-catalog dakota-dso)
add_dependencies (dakota-core    dakota-dso dakota-catalog)
add_dependencies (dakota         dakota-dso dakota-catalog dakota-core)
