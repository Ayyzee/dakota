SO_EXT := dylib
LD_PRELOAD := DYLD_INSERT_LIBRARIES
CXX_NO_WARNINGS := 0
CXX_WARNINGS_FLAGS :=\
 --all-warnings\
 --no-common\
 --trapv\
 --warn-cast-qual\
 --warn-conversion\
 --warn-extra\
 --warn-format=2\
 --warn-missing-format-attribute\
 --warn-missing-include-dirs\
 --warn-no-multichar\
 --warn-no-variadic-macros\
 --warn-pointer-arith\
 --warn-redundant-decls\
 --warn-shadow\
 --warn-switch-default\
 --warn-switch-enum\
 --warn-undef\
 --warn-unused\
 # do not remove this (blank) line

# ALLOW_DESIGNATED_INITIALIZERS
# ALLOW_COMPOUND_LITERALS

CXX_ALLOW_DESIGNATED_INITIALIZERS_FLAGS :=
CXX_ALLOW_COMPOUND_LITERALS_FLAGS :=
