# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (dakota-core-project LANGUAGES CXX)
include (${CMAKE_CURRENT_BINARY_DIR}/build.cmake)
include (${CMAKE_CURRENT_SOURCE_DIR}/install.cmake)
include (${prefix_dir}/lib/dakota/base.cmake)
