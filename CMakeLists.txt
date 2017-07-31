# -*- mode: cmake -*-
cmake_minimum_required (VERSION 3.9)

project (dk)

string (CONCAT CMAKE_PREFIX_PATH
  ":${CMAKE_SOURCE_DIR}/dakota-dso"
  ":${CMAKE_SOURCE_DIR}/dakota-catalog"
  ":${CMAKE_SOURCE_DIR}/dakota-core"
  ":${CMAKE_SOURCE_DIR}/dakota"
  ":${CMAKE_SOURCE_DIR}"
)
string (CONCAT CMAKE_LIBRARY_PATH
  ":${CMAKE_SOURCE_DIR}/dakota-dso/lib"
  ":${CMAKE_SOURCE_DIR}/dakota-core/lib"
  ":${CMAKE_SOURCE_DIR}/dakota/lib"
)
string (CONCAT CMAKE_PROGRAM_PATH
  ":${CMAKE_SOURCE_DIR}/bin"
  ":${CMAKE_SOURCE_DIR}/dakota-catalog/bin"
)
string (CONCAT CMAKE_INCLUDE_PATH
  ":${CMAKE_SOURCE_DIR}/include"
)
add_subdirectory (dakota-dso)
add_subdirectory (dakota-catalog)
add_subdirectory (dakota-core)
add_subdirectory (dakota)

add_dependencies (dakota-catalog dakota-dso)
add_dependencies (dakota-core    dakota-dso dakota-catalog)
add_dependencies (dakota         dakota-dso dakota-catalog dakota-core)
