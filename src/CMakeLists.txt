cmake_minimum_required (VERSION 2.8)

set (BUILD_SHARED_LIBS ON)

#set (CMAKE_CXX_SOURCE_FILE_EXTENSIONS ${CMAKE_CXX_SOURCE_FILE_EXTENSIONS} "dk")
set (CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} -std=c++11)

# CMAKE_SHARED_LIBRARY_SUFFIX

# dakota-info
project (dakota-info CXX)
set (dakota-info-srcs dakota-info.cc)
add_executable        (dakota-info ${dakota-info-srcs})
target_link_libraries (dakota-info LINK_PUBLIC ${CMAKE_DL_LIBS})
set_target_properties (dakota-info
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "../bin"
)

# libdakota.so
project (libfoobar CXX)

set (CMAKE_CXX_COMPILER "/home/robert/dakota/bin/dakota-gcc")
set (CMAKE_COMPILER_IS_GNUCXX 1)

set (libfoobar-srcs foo.dk bar.dk)

add_library (libfoobar SHARED ${libfoobar-srcs})

# hackhack: should be able to add dk to CMAKE_CXX_SOURCE_FILE_EXTENSIONS
set_source_files_properties (${libfoobar-srcs} PROPERTIES LANGUAGE CXX)

# hackhack: should be able to set LANGUAGE to OBJECTIVE_CXX above
set_source_files_properties (${libfoobar-srcs} PROPERTIES COMPILE_FLAGS "--language objective-c++")

target_link_libraries (libfoobar LINK_PUBLIC ${CMAKE_DL_LIBS})
set_target_properties (libfoobar
  PROPERTIES
  LIBRARY_OUTPUT_DIRECTORY "../lib"
  PREFIX ""
  LINKER_LANGUAGE CXX
)
