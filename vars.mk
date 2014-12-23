MAKEFLAGS ?=\
 --no-builtin-rules\
 --no-builtin-variables\
 --no-print-directory\
 --warn-undefined-variables\

# rootdir is set before including this file
srcdir := $(rootdir)/src
local_includedir := $(rootdir)/include

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

DAKOTA_VARS =
DAKOTA_VARS += CXX=$(CXX)
DAKOTA_VARS += SO_EXT=$(SO_EXT)

DAKOTA ?= $(DAKOTA_VARS) $(rootdir)/bin/dakota
#DAKOTA ?= $(DAKOTA_VARS) $(rootdir)/bin/dakota-profile
DAKOTAFLAGS ?=
EXTRA_DAKOTAFLAGS =\
 --include-directory=$(srcdir)\
 --include-directory=$(rootdir)/include\

SO_EXT ?= so

dk_ext := dk
hxx_ext := h
cxx_ext := cc
ctlg_ext := ctlg
lib_prefix := lib
pl_ext := pl
pm_ext := pm
exeext :=

RM := rm
RMFLAGS := -rf

MKDIR := mkdir
MKDIRFLAGS := -p

INSTALL := install
INSTALLFLAGS :=
OWNER := root
GROUP := wheel

CXX ?= g++
CXXFLAGS := -std=c++11

CXX_SHARED_FLAGS ?= --shared
CXX_DYNAMIC_FLAGS ?= --dynamic
CXX_OUTPUT_FLAG := --output
LD_PRELOAD ?= LD_PRELOAD

EXTRA_CXXFLAGS :=\
 --include-directory=$(local_includedir)\
 --include-directory=$(srcdir)\

ifdef DKT_PROFILE
  EXTRA_CXXFLAGS += -pg
  EXTRA_LDFLAGSx += -pg
endif

ifndef DKT_USE_COMPOUND_LITERALS
  EXTRA_CXXFLAGS += --pedantic
endif

ifndef MIN_EXTRA_CXXFLAGS
  EXTRA_CXXFLAGS += --define-macro DEBUG
  #EXTRA_CXXFLAGS += --define-macro DKT_DUMP_MEM_FOOTPRINT
  #EXTRA_CXXFLAGS += --define-macro DKT_USE_MAKE_MACRO
  #ifdef __LP64__
#if defined(__APPLE__) && defined(__MACH__)
  #if SO_EXT eq "dylib"
    #EXTRA_CXXFLAGS_DARWIN_64 := -arch x86_64 -mmacosx-version-min=10.5 -Wshorten-64-to-32
    #EXTRA_CXXFLAGS += $(EXTRA_CXXFLAGS_DARWIN_64)
    #EXTRA_LDFLAGS_DARWIN_64 += -arch x86_64
    #EXTRA_LDFLAGS += $(EXTRA_LDFLAGS_DARWIN_64)
  #endif
  #endif
endif

# clang does not support
#   --no-common
#   --trapv
#   --PIC
EXTRA_CXXFLAGS +=\
 --define-macro HAVE_CONFIG_H\
 -fno-common\
 -ftrapv\
 --debug=3\
 --optimize=0\
 -Wno-multichar\
 -Wno-four-char-constants\
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
 -DMOD_SIZE_CAST_HACK\

 # --warn-redundant-decls
 # --warn-switch-default
 # --no-warnings

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

export EXTRA_LDFLAGS
