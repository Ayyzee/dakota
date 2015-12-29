cmake_minimum_required (VERSION 2.8)

set (CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} -std=c++11)

if (APPLE)
  set (SO_EXT "dylib")
else  (APPLE)
  set (SO_EXT "so")
endif (APPLE)

set (CMAKE_DL_LIBS libdl.${SO_EXT})

# dakota-info
project (dakota-info CXX)
set (DAKOTA_INFO_SRCS dakota-info.cc)
add_executable        (dakota-info ${DAKOTA_INFO_SRCS})
target_link_libraries (dakota-info LINK_PUBLIC ${CMAKE_DL_LIBS})
