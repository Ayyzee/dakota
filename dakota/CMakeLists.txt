# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota-project)
set (target  dakota)
project (${project} LANGUAGES CXX)
include (${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake)
include (${prefix-dir}/lib/dakota/base.cmake)
