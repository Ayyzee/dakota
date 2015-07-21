SHELL := /bin/sh -u

DESTDIR ?=

rootdir ?= ..

srcdir ?= .
blddir := .
objdir ?= $(blddir)/obj

$(shell mkdir -p $(objdir))

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

MAKE := make
MAKEFLAGS :=\
 --no-builtin-rules\
 --no-builtin-variables\
 --warn-undefined-variables\

# --no-print-directory\

include $(shell $(rootdir)/bin/dakota-json2mk --output $(objdir)/compiler.mk\
 $(rootdir)/lib/dakota/compiler.json\
 $(rootdir)/lib/dakota/platform.json)\

CXX := $(DK_CXX)
CXXFLAGS := $(DK_CXXFLAGS)
CXX_WARNINGS_FLAGS := $(DK_CXX_WARNINGS_FLAGS)
CXX_OUTPUT_FLAGS := $(DK_CXX_OUTPUT_FLAGS)

hh_ext := hh
cc_ext := cc

RM := rm
RMFLAGS := -rf

MKDIR := mkdir
MKDIRFLAGS := -p

INSTALL := install
INSTALLFLAGS :=
INSTALL_MODE_FLAGS := -m
INSTALL_CREATE_DIR_FLAGS := -d
INSTALL_OWNER_FLAGS := -o
INSTALL_GROUP_FLAGS := -g
INSTALL_SAFE_COPY := -S

INSTALL_OWNER := root
INSTALL_GROUP := wheel

EXTRA_INSTALLFLAGS := $(INSTALL_OWNER_FLAGS) $(INSTALL_OWNER) $(INSTALL_GROUP_FLAGS) $(INSTALL_GROUP)

#INSTALL_LIB is for shared libraries only
INSTALL_LIB  :=    $(INSTALL) $(INSTALLFLAGS) $(EXTRA_INSTALLFLAGS) $(INSTALL_MODE_FLAGS) 0644 $(INSTALL_SAFE_COPY)
INSTALL_DATA :=    $(INSTALL) $(INSTALLFLAGS) $(EXTRA_INSTALLFLAGS) $(INSTALL_MODE_FLAGS) 0644 $(INSTALL_SAFE_COPY)
INSTALL_PROGRAM := $(INSTALL) $(INSTALLFLAGS) $(EXTRA_INSTALLFLAGS) $(INSTALL_MODE_FLAGS) 0755 $(INSTALL_SAFE_COPY)
INSTALL_DIR :=     $(INSTALL) $(INSTALLFLAGS) $(EXTRA_INSTALLFLAGS) $(INSTALL_MODE_FLAGS) 0755 $(INSTALL_CREATE_DIR_FLAGS)

so_ext ?= so
LD_PRELOAD ?= LD_PRELOAD
CXX_NO_WARNINGS ?= 0

CXX_DEBUG_FLAGS ?= --optimize=0 --debug=3 --define-macro DEBUG

EXTRA_CXXFLAGS := $(CXX_DEBUG_FLAGS)
export EXTRA_CXXFLAGS

ifneq ($(CXX_NO_WARNINGS), 0)
	CXX_WARNINGS_FLAGS += $(CXX_NO_WARNINGS_FLAGS)
endif

ifdef DKT_PROFILE
  DAKOTA ?= $(srcdir)/../bin/dakota-profile
  EXTRA_CXXFLAGS += -pg
  EXTRA_LDFLAGS  += -pg
else
  DAKOTA ?= $(srcdir)/../bin/dakota
  # --keep-going
endif

DAKOTAFLAGS :=
EXTRA_DAKOTAFLAGS := $(DK_HOST_OS)

# cast(some-type-t){...}
ifdef DKT_ALLOW_COMPOUND_LITERALS
  # too broad
  EXTRA_CXXFLAGS += $(CXX_ALLOW_COMPOUND_LITERALS_FLAGS)
endif

# { .x = 0, .y = 0 }
ifdef DKT_ALLOW_DESIGNATED_INITIALIZERS
  # too broad
  EXTRA_CXXFLAGS += $(CXX_ALLOW_DESIGNATED_INITIALIZERS_FLAGS)
endif

#EXTRA_CXXFLAGS += --define-macro DKT_DUMP_MEM_FOOTPRINT

cxx_debug_symbols_ext ?=
