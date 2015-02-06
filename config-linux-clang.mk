CXX := clang++
CXX_NO_WARNINGS := 0
CXX_WARNINGS_FLAGS := -Weverything

# ALLOW_DESIGNATED_INITIALIZERS
# ALLOW_COMPOUND_LITERALS

CXX_ALLOW_DESIGNATED_INITIALIZERS_FLAGS := -Wno-c99-extensions
CXX_ALLOW_COMPOUND_LITERALS_FLAGS := -Wno-c99-extensions

# clang does not support
#   --no-common
#   --trapv
#   --PIC
# it only supports
#   -fno-common
#   -ftrapv
#   -fPIC
