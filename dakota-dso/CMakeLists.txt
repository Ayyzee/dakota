# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota_dso_project)
set (target  dakota-dso)
project (${project} LANGUAGES CXX)
include (${PROJECT_SOURCE_DIR}/build-vars.cmake)
include (${prefix-dir}/lib/dakota/base-cxx.cmake)
