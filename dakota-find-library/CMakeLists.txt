# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (dakota-find-library-project LANGUAGES CXX)
set (target  dakota-find-library)
include (${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake)
include (${prefix_dir}/lib/dakota/base-cxx.cmake)
