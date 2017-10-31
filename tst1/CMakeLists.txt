# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (tst1-project LANGUAGES CXX)
include (${CMAKE_CURRENT_BINARY_DIR}/build.cmake)
include (${prefix_dir}/lib/dakota/base.cmake)
