# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (target dakota-catalog)
set (project ${target}-project)
project (${project} LANGUAGES CXX)
include (${PROJECT_SOURCE_DIR}/build-vars.cmake)
include (${CMAKE_SOURCE_DIR}/lib/dakota/base-cxx.cmake)
