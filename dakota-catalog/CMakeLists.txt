# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota-catalog-project)
project (${project} LANGUAGES CXX)
if (NOT root-source-dir)
  set (root-source-dir ${CMAKE_CURRENT_SOURCE_DIR}/..)
endif ()
include (${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake)
include (${root-source-dir}/lib/dakota/base-cxx.cmake)

add_dependencies (     dakota-catalog dakota-dso)
target_link_libraries (dakota-catalog dakota-dso)
