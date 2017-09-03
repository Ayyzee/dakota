# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project exe-project)
set (target  exe)
project (${project} LANGUAGES CXX)
include (${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake)
include (${prefix-dir}/lib/dakota/base.cmake)
