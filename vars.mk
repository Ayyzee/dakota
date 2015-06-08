MAKE := make
MAKEFLAGS :=\
 --no-builtin-rules\
 --no-builtin-variables\
 --warn-undefined-variables\

# --no-print-directory\

hh_ext := hh
cc_ext := cc
lib_prefix := lib

RM := rm
RMFLAGS := -rf

MKDIR := mkdir
MKDIRFLAGS := -p

INSTALL := install
INSTALLFLAGS :=
INSTALL_MODE_FLAG := -m
INSTALL_CREATE_DIRS_FLAG := -d
INSTALL_OWNER_FLAG := -o
INSTALL_GROUP_FLAG := -g

OWNER := root
GROUP := wheel

so_ext ?= so
LD_PRELOAD ?= LD_PRELOAD
CXX_NO_WARNINGS ?= 0

CXX_DEBUG_FLAGS ?= --optimize=0 --debug=3 --define-macro DEBUG

EXTRA_CXXFLAGS := $(CXX_DEBUG_FLAGS)

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
EXTRA_DAKOTAFLAGS :=

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
