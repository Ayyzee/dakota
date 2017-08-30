# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota_catalog_project)
set (target  dakota-catalog)
project (${project} LANGUAGES CXX)
include (${PROJECT_SOURCE_DIR}/build-vars.cmake)
include (${prefix}/lib/dakota/base-cxx.cmake)
