export SO_EXT := dylib
export LD_NAME_FLAG := -install_name
export CXX_SHARED_FLAGS := -dynamiclib
export CXX_DYNAMIC_FLAGS := -dynamiclib

export LD_PRELOAD := DYLD_INSERT_LIBRARIES
