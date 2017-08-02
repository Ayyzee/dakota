# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota-lang-project)
project (${project} LANGUAGES CXX)

set (root-source-dir ${CMAKE_CURRENT_SOURCE_DIR})

add_subdirectory (dakota-dso)
add_subdirectory (dakota-catalog)
add_subdirectory (dakota-core)
add_subdirectory (dakota)
