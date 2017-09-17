# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (dakota-catalog-project LANGUAGES CXX)
set (target dakota-catalog)
include (${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake)
include (${prefix-dir}/lib/dakota/base-cxx.cmake)
