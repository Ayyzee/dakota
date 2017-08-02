# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota-project)
project (${project} LANGUAGES CXX)
set (target-ast dakota-target-ast)
set (target-hdr dakota-target-hdr)
include (${CMAKE_CURRENT_SOURCE_DIR}/../lib/dakota/base.cmake)
