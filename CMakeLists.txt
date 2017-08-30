# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
set (project dakota_lang_project)
project (${project} LANGUAGES CXX)

set (source-dir ${dakota_lang_project_SOURCE_DIR})
set (prefix     ${dakota_lang_project_SOURCE_DIR})

add_subdirectory (dakota-dso)
add_subdirectory (dakota-catalog)
add_subdirectory (dakota-core)
add_subdirectory (dakota)
add_subdirectory (exe-core)
add_subdirectory (exe)
