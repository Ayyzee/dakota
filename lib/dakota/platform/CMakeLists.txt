# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)
project (platform-project LANGUAGES CXX)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/platform.yaml.in ${CMAKE_CURRENT_SOURCE_DIR}/../platform.yaml)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/platform.mk.in   ${CMAKE_CURRENT_SOURCE_DIR}/../platform.mk)
