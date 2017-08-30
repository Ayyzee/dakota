# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project exe_core_project)
set (target  exe-core)
project (${project} LANGUAGES CXX)
include (${PROJECT_SOURCE_DIR}/build-vars.cmake)
include (${prefix}/lib/dakota/base-cxx.cmake)
include (${prefix}/lib/dakota/base.cmake)
