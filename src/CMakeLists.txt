# dakota-info
project (dakota-info CXX)
set (dakota-info-srcs dakota-info.cc)
add_executable        (dakota-info ${dakota-info-srcs})
target_link_libraries (dakota-info LINK_PUBLIC ${CMAKE_DL_LIBS})
set_target_properties (dakota-info
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/bin"
)

# libfoo.so
project (libfoo CXX)

set (CMAKE_CXX_COMPILER "/home/robert/dakota/bin/dakota-gcc")
set (CMAKE_COMPILER_IS_GNUCXX 1)

set (libfoo-srcs foo1.dk foo2.dk)

add_library (libfoo SHARED ${libfoo-srcs})

# hackhack: should be able to add dk to CMAKE_CXX_SOURCE_FILE_EXTENSIONS
set_source_files_properties (${libfoo-srcs} PROPERTIES LANGUAGE CXX)

# hackhack: should be able to set LANGUAGE to OBJECTIVE_CXX above
set_source_files_properties (${libfoo-srcs} PROPERTIES COMPILE_FLAGS "--language objective-c++")

target_link_libraries (libfoo LINK_PUBLIC ${CMAKE_DL_LIBS})
set_target_properties (libfoo
  PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/lib"
    PREFIX ""
    LINKER_LANGUAGE CXX
)
