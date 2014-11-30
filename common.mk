SHELL := /bin/sh -u

MAKEFLAGS ?=\
 --no-builtin-rules\
 --no-builtin-variables\
 --no-print-directory\
 --warn-undefined-variables\

srcdir ?= .

prefix ?= /usr/local
includedir := $(prefix)/include
libdir :=     $(prefix)/lib
bindir :=     $(prefix)/bin

DESTDIR ?=

CXX_SHARED_FLAGS ?= --shared
CXX_DYNAMIC_FLAGS ?= --dynamic
CXX_OUTPUT_FLAG := --output
LD_PRELOAD ?= LD_PRELOAD

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
