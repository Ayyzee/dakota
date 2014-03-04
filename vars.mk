include $(rootdir)/config.mk

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

DAKOTA := dakota
EXTRA_DAKOTAFLAGS := --include-directory=$(includedir) --include-directory=. --define-macro DEBUG
DAKOTAFLAGS ?=

SO_EXT ?= so

MAKEFLAGS := --no-print-directory --no-builtin-rules --no-builtin-variables --warn-undefined-variables

CXX ?= g++
CXXFLAGS ?= --no-warnings

 EXTRA_CXXFLAGS +=\
 --no-common\
 --trapv\
 --debug=3\
 --optimize=0\
 --ansi\
 --all-warnings\
 --warn-cast-align\
 --warn-cast-qual\
 --warn-extra\
 --warn-missing-format-attribute\
 --warn-missing-include-dirs\
 --warn-no-variadic-macros\
 --warn-pointer-arith\
 --warn-shadow\
 --warn-switch-enum\
 --warn-undef\
 --warn-unused\
 --warn-no-multichar

export CXXFLAGS
export EXTRA_CXXFLAGS

CXX_SHARED_FLAGS ?= --shared -fPIC
CXX_DYNAMIC_FLAGS ?= --dynamic -fPIC
CXX_OUTPUT_FLAG := --output
LD_PRELOAD ?= LD_PRELOAD
