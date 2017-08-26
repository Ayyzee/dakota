# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota-lang-project)
project (${project} LANGUAGES CXX)

add_subdirectory (libdakota-dso)
add_subdirectory (dakota-catalog)
add_subdirectory (libdakota-core)
add_subdirectory (libdakota)
add_subdirectory (exe-core)
add_subdirectory (exe)
