# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (dakota-catalog-project LANGUAGES CXX)
set (target dakota-catalog)
include (${CMAKE_CURRENT_SOURCE_DIR}/build.cmake)
include (${prefix_dir}/lib/dakota/base-cxx.cmake)
