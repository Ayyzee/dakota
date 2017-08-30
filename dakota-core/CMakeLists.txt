# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota_core_project)
set (target  dakota-core)
project (${project} LANGUAGES CXX)
include (${PROJECT_SOURCE_DIR}/build-vars.cmake)
include (${PROJECT_SOURCE_DIR}/install.cmake)
include (${prefix}/lib/dakota/base-cxx.cmake)
include (${prefix}/lib/dakota/base.cmake)
