SHELL := /bin/bash -e -u

DESTDIR ?=

rootdir ?= ..

srcdir ?= .
blddir := .
objdir ?= $(blddir)/obj
objdir-name := $(notdir $(objdir))

$(shell mkdir -p $(objdir))

prefix ?= /usr/local

MAKE := make
MAKEFLAGS +=\
 --no-builtin-rules\
 --no-builtin-variables\
 --warn-undefined-variables\

# --no-print-directory\

include $(shell $(rootdir)/bin/dakota-json2mk --output $(objdir)/compiler.mk\
 $(rootdir)/lib/dakota/compiler.json\
 $(rootdir)/lib/dakota/platform.json)\

hh_ext := hh
cc_ext := cc

CP := cp
CPFLAGS := -pR

RM := rm
RMFLAGS := -fr

LN := ln
LNFLAGS := -s

MKDIR := mkdir
MKDIRFLAGS := -p

INSTALL_CREATE_PARENT_DIR_FLAGS := # -D # linux only (absent on darwin)
INSTALL := install
INSTALLFLAGS := $(INSTALL_CREATE_PARENT_DIR_FLAGS)
INSTALL_MODE_FLAGS := -m
INSTALL_OWNER_FLAGS := -o
INSTALL_GROUP_FLAGS := -g
INSTALL_SAFE_COPY_FLAGS := -S

INSTALL_OWNER := root
INSTALL_GROUP := wheel
INSTALL_MODE_LIB :=     0644
INSTALL_MODE_DATA :=    0644
INSTALL_MODE_PROGRAM := 0755

EXTRA_INSTALLFLAGS := $(INSTALL_SAFE_COPY_FLAGS) $(INSTALL_OWNER_FLAGS) $(INSTALL_OWNER) $(INSTALL_GROUP_FLAGS) $(INSTALL_GROUP)

#INSTALL_LIB is for shared libraries only
INSTALL_LIB  :=    $(INSTALL) $(INSTALLFLAGS) $(EXTRA_INSTALLFLAGS) $(INSTALL_MODE_FLAGS) $(INSTALL_MODE_LIB)
INSTALL_DATA :=    $(INSTALL) $(INSTALLFLAGS) $(EXTRA_INSTALLFLAGS) $(INSTALL_MODE_FLAGS) $(INSTALL_MODE_DATA)
INSTALL_PROGRAM := $(INSTALL) $(INSTALLFLAGS) $(EXTRA_INSTALLFLAGS) $(INSTALL_MODE_FLAGS) $(INSTALL_MODE_PROGRAM)

# not really ideal, but it works since the target-triplet is a directory that may/may-not be part of a path
target-triplet := .
so_ext ?= so
LD_PRELOAD ?= LD_PRELOAD

EXTRA_CXXFLAGS += --optimize=0 --debug=3 # debug flags
EXTRA_CXXFLAGS += --define-macro DEBUG   # debug flags
#EXTRA_CXXFLAGS += $(CXX_COMPILE_THREAD_FLAGS)
#EXTRA_CXXFLAGS += -MMD -MP

ifdef DKT_PROFILE
  DAKOTA ?= DK_ENABLE_TRACE_MACROS=1 $(srcdir)/../bin/dakota-profile --define-macro DK_ENABLE_TRACE_MACROS=1 --define-macro $(HOST_OS)
  EXTRA_CXXFLAGS += -pg
  EXTRA_LDFLAGS  += -pg
else
  DAKOTA ?= DK_NO_LINE=0 DK_NO_CONVERT_DASH_SYNTAX=0 DK_ENABLE_TRACE_MACROS=1 $(srcdir)/../bin/dakota --define-macro DK_ENABLE_TRACE_MACROS=1 --define-macro $(HOST_OS)
  # --keep-going
endif

DAKOTA_INFO ?= $(blddir)/../bin/dakota-info

DAKOTAFLAGS ?=
EXTRA_DAKOTAFLAGS ?=

#EXTRA_CXXFLAGS += --define-macro DKT_DUMP_MEM_FOOTPRINT

cxx_debug_symbols_ext ?=

export DAKOTA_INFO
export EXTRA_CXXFLAGS
