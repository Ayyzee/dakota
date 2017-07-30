# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)

project (dk) # dakota

add_subdirectory (dakota-dso)     # dakota-dso-so
add_subdirectory (dakota-catalog)
add_subdirectory (dakota-core)    # dakota-core-so
add_subdirectory (dakota)         # dakota-so

add_dependencies (dakota         dakota-dso dakota-catalog dakota-core) # dakota-so
add_dependencies (dakota-core    dakota-dso dakota-catalog)
add_dependencies (dakota-catalog dakota-dso)
