# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota_core_project)
set (target  dakota-core)
project (${project} LANGUAGES CXX)
include (${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake)
include (${CMAKE_CURRENT_SOURCE_DIR}/install.cmake)
include (${prefix-dir}/lib/dakota/base-cxx.cmake)
include (${prefix-dir}/lib/dakota/base.cmake)
