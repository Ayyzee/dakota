SHELL := /bin/bash -o errexit -o nounset -o pipefail

DESTDIR ?=

rootdir ?= .
include $(rootdir)/makeflags.mk

srcdir ?= .
blddir := .
objdir ?= $(blddir)/obj
objdir-name := $(notdir $(objdir))

prefix ?= /usr/local

hh_ext := hh
cc_ext := cc

CP := cp
CPFLAGS ?= --recursive --preserve=mode,ownership,timestamps

RM := rm
RMFLAGS ?= --force --recursive

LN := ln
LNFLAGS ?= --symbolic --force

MKDIR := mkdir
MKDIRFLAGS ?= --parents

$(shell $(MKDIR) $(MKDIRFLAGS) $(objdir))

platform := $(shell source $(rootdir)/common.sh; platform)
compiler := $(shell source $(rootdir)/common.sh; compiler)

include $(shell $(rootdir)/bin/dakota-json2mk --output $(objdir)/compiler.mk\
 $(rootdir)/lib/dakota/compiler/command-line.json\
 $(rootdir)/lib/dakota/platform.json)\

INSTALL := install
INSTALLFLAGS :=
INSTALL_MODE_FLAGS ?=  --mode
INSTALL_OWNER_FLAGS ?= --owner
INSTALL_GROUP_FLAGS ?= --group

INSTALL_OWNER := root
INSTALL_GROUP := staff
INSTALL_MODE_LIB :=     0644
INSTALL_MODE_DATA :=    0644
INSTALL_MODE_PROGRAM := 0755

EXTRA_INSTALLFLAGS := $(INSTALL_OWNER_FLAGS) $(INSTALL_OWNER) $(INSTALL_GROUP_FLAGS) $(INSTALL_GROUP)

#INSTALL_LIB is for shared libraries only
INSTALL_LIB  :=    $(INSTALL) $(INSTALLFLAGS) $(EXTRA_INSTALLFLAGS) $(INSTALL_MODE_FLAGS) $(INSTALL_MODE_LIB)
INSTALL_DATA :=    $(INSTALL) $(INSTALLFLAGS) $(EXTRA_INSTALLFLAGS) $(INSTALL_MODE_FLAGS) $(INSTALL_MODE_DATA)
INSTALL_PROGRAM := $(INSTALL) $(INSTALLFLAGS) $(EXTRA_INSTALLFLAGS) $(INSTALL_MODE_FLAGS) $(INSTALL_MODE_PROGRAM)

so_ext ?= so
LD_PRELOAD ?= LD_PRELOAD

EXTRA_CXXFLAGS += --optimize=0 --debug=3 # debug flags
EXTRA_CXXFLAGS += --define-macro DEBUG   # debug flags
#EXTRA_CXXFLAGS += $(CXX_COMPILE_THREAD_FLAGS)
#EXTRA_CXXFLAGS += -MMD -MP

DAKOTA-BASE = $(srcdir)/../bin/dakota

ifdef DKT_PROFILE
  DAKOTA ?= DK_ECHO_LINK_CMD=0 DK_NO_LINE=0 DK_NO_CONVERT_DASH_SYNTAX=0 $(srcdir)/../bin/dakota-profile
  # prof uses -p, gprof uses -pg
  EXTRA_CXXFLAGS += -pg
  EXTRA_LDFLAGS  += -pg
else
  DAKOTA ?= DK_ECHO_LINK_CMD=0 DK_NO_LINE=0 DK_NO_CONVERT_DASH_SYNTAX=0 $(DAKOTA-BASE)
  # --keep-going
endif

DAKOTA_CATALOG ?= $(blddir)/../bin/dakota-catalog

DAKOTAFLAGS ?=
EXTRA_DAKOTAFLAGS ?=

#EXTRA_CXXFLAGS += --define-macro DKT_DUMP_MEM_FOOTPRINT

cxx_debug_symbols_ext ?=

export DAKOTA_CATALOG
export EXTRA_CXXFLAGS
