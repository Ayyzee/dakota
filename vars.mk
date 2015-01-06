MAKE := gnumake
MAKEFLAGS :=\
 --no-builtin-rules\
 --no-builtin-variables\
 --no-print-directory\
 --warn-undefined-variables\

DESTDIR := /

# rootdir is set before including this file
SRCDIR :=     $(rootdir)/src
INCLUDEDIR := $(rootdir)/include
LIBDIR :=     $(rootdir)/lib
BINDIR :=     $(rootdir)/bin

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

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

DAKOTA_VARS =
DAKOTA_VARS += CXX=$(CXX)
DAKOTA_VARS += SO_EXT=$(SO_EXT)

DAKOTA ?= $(DAKOTA_VARS) $(BINDIR)/dakota #--keep-going
#DAKOTA ?= $(DAKOTA_VARS) $(rootdir)/bin/dakota-profile
DAKOTAFLAGS ?=
INCLUDE_DAKOTAFLAGS :=\
 --include-directory $(SRCDIR)\
 --include-directory $(INCLUDEDIR)\

EXTRA_CXXFLAGS :=

ifdef DKT_PROFILE
  EXTRA_CXXFLAGS += -pg
  EXTRA_LDFLAGS  += -pg
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

#-Wmultichar -Wno-multichar

# -fshow-column\
 -fshow-source-location\
 -fcaret-diagnostics\
 -fdiagnostics-format=clang\
 -fdiagnostics-show-option\

# --no-warnings

# -fno-common\
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


#diagnostics-format rhs = clang|msvc|vi

EXTRA_CXXFLAGS += $(CXXFLAGS_WARNINGS_ALL)\
 --debug=3\
 --optimize=0\
 --define-macro DEBUG\
 --define-macro HAVE_CONFIG_H\
 --define-macro MOD_SIZE_CAST_HACK\

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

export DAKOTA
export DAKOTAFLAGS
export INCLUDE_DAKOTAFLAGS

export EXTRA_LDFLAGS
