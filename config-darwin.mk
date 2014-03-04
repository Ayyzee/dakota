export SO_EXT := dylib
export LD_NAME_FLAG := -install_name
export CXX_SHARED_FLAGS := -dynamiclib -fPIC
export CXX_DYNAMIC_FLAGS := -dynamiclib -fPIC

export LD_PRELOAD := DYLD_INSERT_LIBRARIES
