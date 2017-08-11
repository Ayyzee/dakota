# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (target dakota-core)
set (project ${target}-project)
project (${project} LANGUAGES CXX)
set (current-source-build-vars ${CMAKE_CURRENT_SOURCE_DIR}/build-vars.cmake)
include (${current-source-build-vars})
include (${CMAKE_SOURCE_DIR}/lib/dakota/base.cmake)
include (${CMAKE_CURRENT_SOURCE_DIR}/install.cmake)
