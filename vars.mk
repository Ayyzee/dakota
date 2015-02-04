MAKE := make
MAKEFLAGS :=\
 --no-builtin-rules\
 --no-builtin-variables\
 --warn-undefined-variables\

# --no-print-directory\

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
hxx_ext := hh
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

CXX_OPTIMIZE_FLAGS ?= --optimize=0
CXX_DEBUG_FLAGS ?= --debug=3 --define-macro DEBUG
CXX_SHARED_FLAGS ?= --shared
CXX_DYNAMIC_FLAGS ?= --dynamic
CXX_OUTPUT_FLAG := --output
CXX_NO_WARNINGS_FLAGS := --no-warnings

ifneq ($(CXX_NO_WARNINGS), 0)
	CXX_WARNINGS_FLAGS += $(CXX_NO_WARNING_FLAGS)
endif

LD_PRELOAD ?= LD_PRELOAD

DAKOTA_VARS =
DAKOTA_VARS += CXX=$(CXX)
DAKOTA_VARS += SO_EXT=$(SO_EXT)

ifdef DKT_PROFILE
  DAKOTA ?= $(DAKOTA_VARS) $(BINDIR)/dakota-profile
  EXTRA_CXXFLAGS += -pg
  EXTRA_LDFLAGS  += -pg
else
  DAKOTA ?= $(DAKOTA_VARS) $(BINDIR)/dakota #--keep-going
endif

DAKOTAFLAGS ?=
EXTRA_DAKOTAFLAGS :=\
 --include-directory $(SRCDIR)\
 --include-directory $(INCLUDEDIR)\

EXTRA_CXXFLAGS :=

# cast(some-type-t){...}
ifdef DKT_ALLOW_COMPOUND_LITERALS
  EXTRA_CXXFLAGS += -Wno-c99-extensions # too broad
endif

# { .x = 0, .y = 0 }
ifdef DKT_ALLOW_DESIGNATED_INITIALIZERS
  EXTRA_CXXFLAGS += -Wno-c99-extensions # too broad
endif

EXTRA_CXXFLAGS += $(CXX_WARNINGS_FLAGS)
EXTRA_CXXFLAGS += $(CXX_OPTIMIZE_FLAGS)
EXTRA_CXXFLAGS += $(CXX_DEBUG_FLAGS)

EXTRA_CXXFLAGS +=\
 --define-macro HAVE_CONFIG_H\
 --define-macro MOD_SIZE_CAST_HACK\
 --define-macro DKT_WORKAROUND\

#EXTRA_CXXFLAGS += --define-macro DKT_DUMP_MEM_FOOTPRINT

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

export EXTRA_LDFLAGS
