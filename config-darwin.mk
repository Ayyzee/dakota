export SO_EXT := dylib
export LD_SONAME_FLAGS := -install_name
export CXX := clang++
export CXX_COMPILE_FLAGS := --compile
export CXX_SHARED_FLAGS := -dynamiclib
export CXX_DYNAMIC_FLAGS := -dynamiclib
export CXX_OUTPUT_FLAGS := --output
export CXX_OPTIMIZE_FLAGS := --optimize=0
export CXX_DEBUG_FLAGS :=\
 --debug=3\
 --define-macro DEBUG\

CXX_NO_WARNINGS ?= 0

ifneq ($(CXX_NO_WARNINGS), 0)
	export CXX_WARNING_FLAGS := --no-warnings
else
  export CXX_WARNING_FLAGS :=\
 -Weverything\
 -Wno-c++98-compat\
 -Wno-c++98-compat-pedantic\
 -Wno-multichar\
 -Wno-old-style-cast\
 -Wno-global-constructors\
 -Wno-padded\
 -Wno-cast-align\
 -Wno-disabled-macro-expansion\
 -Wno-deprecated\
 -Wno-exit-time-destructors\
 # do not remove this (blank) line
endif

export LD_PRELOAD := DYLD_INSERT_LIBRARIES
