# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (exe-project LANGUAGES CXX)
set (target exe)
include (${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake)
include (${prefix-dir}/lib/dakota/base.cmake)
