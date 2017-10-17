# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (dakota-dso-project LANGUAGES CXX)
set (target dakota-dso)
include (${CMAKE_CURRENT_SOURCE_DIR}/build.cmake)
include (${prefix_dir}/lib/dakota/base-cxx.cmake)
