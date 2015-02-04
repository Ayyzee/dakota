SO_EXT := dylib
LD_PRELOAD := DYLD_INSERT_LIBRARIES
CXX := g++
CXX_WARNINGS_FLAGS :=\
 -fno-common\
 -ftrapv\
 --all-warnings\
 --warn-cast-qual\
 --warn-extra\
 --warn-format=2\
 --warn-missing-format-attribute\
 --warn-missing-include-dirs\
 --warn-no-variadic-macros\
 --warn-pointer-arith\
 --warn-shadow\
 --warn-switch-enum\
 --warn-undef\
 --warn-unused\
 --warn-no-multichar\
 --warn-conversion\
 --warn-redundant-decls\
 --warn-switch-default\
 # do not remove this (blank) line

CXX_NO_WARNINGS ?= 0

