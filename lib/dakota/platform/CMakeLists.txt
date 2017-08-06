cmake_minimum_required (VERSION 3.9)
set (project platform-project)
project (${project} LANGUAGES CXX)
configure_file (${CMAKE_SOURCE_DIR}/platform.yaml.in ${CMAKE_SOURCE_DIR}/../platform.yaml)
