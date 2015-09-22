# Makefile

include config.mk

cxx_shared_flags :=  -shared
cxx_dynamic_flags := -dynamic

ifdef DARWIN_GCC
  cxx_shared_flags :=  -dynamiclib -single_module
  cxx_dynamic_flags := -dynamiclib -single_module
endif

all:
	@echo $(MAKEFLAGS)
	@echo $(cxx_shared_flags)
	@echo $(cxx_dynamic_flags)
	@echo $(so_ext)
