# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (tst2-project LANGUAGES CXX)
set (target tst2)
include (${CMAKE_CURRENT_SOURCE_DIR}/build.cmake)
include (${prefix_dir}/lib/dakota/base.cmake)
