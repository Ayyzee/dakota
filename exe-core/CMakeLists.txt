# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (exe-core-project LANGUAGES CXX)
set (target exe-core)
include (${CMAKE_CURRENT_SOURCE_DIR}/build.cmake)
include (${prefix_dir}/lib/dakota/base.cmake)
