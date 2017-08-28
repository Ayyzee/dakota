# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (target dakota)
set (project ${target}-project)
project (${project} LANGUAGES CXX)
include (${PROJECT_SOURCE_DIR}/build-vars.cmake)
include (${dakota-lang-source-dir}/lib/dakota/base.cmake)
