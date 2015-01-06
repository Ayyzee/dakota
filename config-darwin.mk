export SO_EXT := dylib
export LD_NAME_FLAG := -install_name
export CXX := clang++
export CXX_SHARED_FLAGS := -dynamiclib
export CXX_DYNAMIC_FLAGS := -dynamiclib
export CXXFLAGS_WARNINGS_ALL :=\
 -Weverything\
 -Wno-c++98-compat\
 -Wno-c++98-compat-pedantic\
 -Wno-multichar\
 -Wno-old-style-cast\
 -Wno-global-constructors\
 -Wno-padded\
 -Wno-cast-align\
 -Wno-disabled-macro-expansion\

export LD_PRELOAD := DYLD_INSERT_LIBRARIES
