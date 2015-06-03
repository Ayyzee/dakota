MAKE := make
MAKEFLAGS :=\
 --no-builtin-rules\
 --no-builtin-variables\
 --warn-undefined-variables\

# --no-print-directory\

# rootdir is set before including this file
srcdir ?= $(rootdir)/src

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
CXX_NO_WARNINGS ?= 0

CXX_DEBUG_FLAGS ?= --optimize=0 --debug=3 --define-macro DEBUG

ifneq ($(CXX_NO_WARNINGS), 0)
	CXX_WARNINGS_FLAGS += $(CXX_NO_WARNINGS_FLAGS)
endif

ifdef DKT_PROFILE
  DAKOTA ?= $(rootdir)/bin/dakota-profile
  EXTRA_CXXFLAGS += -pg
  EXTRA_LDFLAGS  += -pg
else
  DAKOTA ?= $(rootdir)/bin/dakota #--keep-going
endif

DAKOTAFLAGS ?=
EXTRA_DAKOTAFLAGS :=

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

export EXTRA_CXXFLAGS

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

export EXTRA_LDFLAGS
