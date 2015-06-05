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
OWNER := root
GROUP := wheel

SO_EXT ?= so
LD_PRELOAD ?= LD_PRELOAD
CXX_NO_WARNINGS ?= 0

CXX_DEBUG_FLAGS ?= --optimize=0 --debug=3 --define-macro DEBUG

EXTRA_CXXFLAGS := $(CXX_DEBUG_FLAGS)

ifneq ($(CXX_NO_WARNINGS), 0)
	CXX_WARNINGS_FLAGS += $(CXX_NO_WARNINGS_FLAGS)
endif

ifdef DKT_PROFILE
  DAKOTA ?= ../bin/dakota-profile # fixfix: should use $(srcdir)/../bin
  EXTRA_CXXFLAGS += -pg
  EXTRA_LDFLAGS  += -pg
else
  DAKOTA ?= ../bin/dakota #--keep-going # fixfix: should use $(srcdir)/../bin
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

#EXTRA_CXXFLAGS += --define-macro DKT_DUMP_MEM_FOOTPRINT
