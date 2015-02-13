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

dk_ext := dk
hxx_ext := hh
cxx_ext := cc
ctlg_ext := ctlg
lib_prefix := lib
pl_ext := pl
pm_ext := pm

RM := rm
RMFLAGS := -rf

MKDIR := mkdir
MKDIRFLAGS := -p

INSTALL := install
INSTALLFLAGS :=
OWNER := root
GROUP := wheel

SO_EXT ?= so
LD_PRELOAD ?= LD_PRELOAD
CXX ?= g++
CXX_WARNINGS_FLAGS ?= --warnings-all
CXX_NO_WARNINGS ?= 0
CXXFLAGS := -std=c++11

CXX_DEBUG_FLAGS ?= --optimize=0 --debug=3 --define-macro DEBUG
CXX_SHARED_FLAGS ?= --shared
CXX_DYNAMIC_FLAGS ?= --dynamic
CXX_OUTPUT_FLAGS := --output
CXX_NO_WARNINGS_FLAGS := --no-warnings

ifneq ($(CXX_NO_WARNINGS), 0)
	CXX_WARNINGS_FLAGS += $(CXX_NO_WARNINGS_FLAGS)
endif

ifdef DKT_PROFILE
  DAKOTA ?= DK_PREFIX=$(rootdir) $(BINDIR)/dakota-profile
  EXTRA_CXXFLAGS += -pg
  EXTRA_LDFLAGS  += -pg
else
  DAKOTA ?= DK_PREFIX=$(rootdir) $(BINDIR)/dakota #--keep-going
endif

DAKOTAFLAGS ?=
EXTRA_DAKOTAFLAGS :=
EXTRA_CXXFLAGS := $(CXX_WARNINGS_FLAGS)

# cast(some-type-t){...}
ifdef DKT_ALLOW_COMPOUND_LITERALS
  EXTRA_CXXFLAGS += $(CXX_ALLOW_COMPOUND_LITERALS_FLAGS) # too broad
endif

# { .x = 0, .y = 0 }
ifdef DKT_ALLOW_DESIGNATED_INITIALIZERS
  EXTRA_CXXFLAGS += $(CXX_ALLOW_DESIGNATED_INITIALIZERS_FLAGS) # too broad
endif

EXTRA_CXXFLAGS += $(CXX_DEBUG_FLAGS)

#EXTRA_CXXFLAGS += --define-macro DKT_DUMP_MEM_FOOTPRINT

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

export EXTRA_LDFLAGS
