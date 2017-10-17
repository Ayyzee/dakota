# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (exe-project LANGUAGES CXX)
set (target exe)
include (${CMAKE_CURRENT_SOURCE_DIR}/build.cmake)
include (${prefix_dir}/lib/dakota/base.cmake)
