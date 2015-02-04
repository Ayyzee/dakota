SO_EXT := dylib
LD_PRELOAD := DYLD_INSERT_LIBRARIES
CXX := clang++
CXX_WARNINGS_FLAGS :=\
 -Weverything\
 -Wno-c++98-compat-pedantic\
 -Wno-c++98-compat\
 -Wno-cast-align\
 -Wno-deprecated\
 -Wno-disabled-macro-expansion\
 -Wno-exit-time-destructors\
 -Wno-four-char-constants\
 -Wno-global-constructors\
 -Wno-multichar\
 -Wno-old-style-cast\
 -Wno-padded\
 # do not remove this (blank) line

CXX_NO_WARNINGS := 0

# clang does not support
#   --no-common
#   --trapv
#   --PIC
# it only supports
#   -fno-common
#   -ftrapv
#   -fPIC
