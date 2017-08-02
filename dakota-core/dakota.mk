rootdir := ..

SOURCE_DIR := $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST))))

build-dir := $(shell $(rootdir)/bin/dakota-build build-dir dakota.build)

include $(rootdir)/common.mk
include $(shell $(rootdir)/bin/dakota-build2mk --output dk-vars.mk dakota.build)
target := lib$(target).$(so_ext)

.PRECIOUS: %.project

.PHONY:\
 all\
 clean\
 install\
 uninstall\

all: $(target)

$(target): $(srcs)

uninstall:
	sudo $(RM) $(RMFLAGS) $(install.files) $(install-links)

install-dirs :=  $(INSTALL_PREFIX)/bin $(INSTALL_PREFIX)/include $(INSTALL_PREFIX)/lib/dakota
install-links := $(INSTALL_PREFIX)/lib/dakota/compiler-command-line.json $(INSTALL_PREFIX)/lib/dakota/platform.json

$(install-dirs):
	sudo $(MKDIR) $(MKDIRFLAGS) $@

install: all $(install-dirs) $(install.files) $(install-links)

clean: | dakota.project
	$(DAKOTA-BASE) --project dakota.project --clean
	$(RM) $(RMFLAGS) $(target)
	$(RM) $(RMFLAGS) $(build-dir)
	$(RM) $(RMFLAGS) dk-compiler.mk dk-vars.mk
	$(RM) $(RMFLAGS) $(SOURCE_DIR)/strerror-name-tbl.inc

$(SOURCE_DIR)/strerror-name.dk: $(SOURCE_DIR)/strerror-name-tbl.inc

$(INSTALL_PREFIX)/lib/dakota/platform.json:              $(INSTALL_PREFIX)/lib/dakota/platform-$(platform).json
$(INSTALL_PREFIX)/lib/dakota/compiler-command-line.json: $(INSTALL_PREFIX)/lib/dakota/compiler-command-line-$(compiler).json
