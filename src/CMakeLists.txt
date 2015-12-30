cmake_minimum_required (VERSION 2.8)

set (CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} -std=c++11)

# CMAKE_SHARED_LIBRARY_SUFFIX

# dakota-info
project (dakota-info CXX)
set (DAKOTA_INFO_SRCS dakota-info.cc)
add_executable        (dakota-info ${DAKOTA_INFO_SRCS})
target_link_libraries (dakota-info LINK_PUBLIC ${CMAKE_DL_LIBS})
set_target_properties (dakota-info
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "../bin"
)

# libdakota.so
project (libfoobar CXX)

set (FOOBAR_SRCS foo.cc bar.cc)
add_library           (libfoobar SHARED ${FOOBAR_SRCS})
target_link_libraries (libfoobar LINK_PUBLIC ${CMAKE_DL_LIBS})
set_target_properties (libfoobar
  PROPERTIES
  LIBRARY_OUTPUT_DIRECTORY "../lib"
  PREFIX ""
  # LINKER_LANGUAGE CXX
)
