cmake_minimum_required (VERSION 3.9)
set (project platform_project)
project (${project} LANGUAGES CXX)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/platform.yaml.in ${CMAKE_CURRENT_SOURCE_DIR}/../platform.yaml)
