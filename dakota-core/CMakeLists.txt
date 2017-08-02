# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota-core-project)
project (${project} LANGUAGES CXX)
set (target-ast dakota-core-target-ast)
set (target-hdr dakota-core-target-hdr)
include (${CMAKE_CURRENT_SOURCE_DIR}/../lib/dakota/base.cmake)
include (${CMAKE_CURRENT_SOURCE_DIR}/install.cmake)
