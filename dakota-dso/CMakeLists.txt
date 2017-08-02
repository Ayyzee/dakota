# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota-dso-project)
project (${project} LANGUAGES CXX)
if (NOT root-source-dir)
  set (root-source-dir ${CMAKE_CURRENT_SOURCE_DIR}/..)
endif ()
include (${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake)
include (${root-source-dir}/lib/dakota/base-cxx.cmake)
