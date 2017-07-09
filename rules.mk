ifndef macros
	macros :=
endif
ifndef include-dirs
	include-dirs :=
endif
ifndef lib-dirs
	lib-dirs :=
endif
ifndef libs
	libs :=
endif

cxx-opts = $(macros:%=$(CXX_DEFINE_MACRO_FLAGS) %) $(include-dirs:%=$(CXX_INCLUDE_DIRECTORY_FLAGS) %) $(lib-dirs:%=$(CXX_LIBRARY_DIRECTORY_FLAGS) %) $(libs:%=$(CXX_LIBRARY_FLAGS) %)
opts =     $(macros:%=--define-macro %) $(include-dirs:%=--include-directory %) $(lib-dirs:%=--library-directory %) $(libs:%=--library %)

%.inc: $(SOURCE_DIR)/%.pl
	./$< > $@

$(builddir)/%.project: %.build
	$(rootdir)/bin/dakota-build2project $< $@

$(SOURCE_DIR)/lib%.$(so_ext): $(SOURCE_DIR)/%.$(cc_ext)
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) $(builddir)/dakota.project
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(cxx-opts) $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $^

$(SOURCE_DIR)/%: $(SOURCE_DIR)/%.$(cc_ext)
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) $(builddir)/dakota.project
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(cxx-opts) $(CXX_OUTPUT_FLAGS) $@ $^

$(SOURCE_DIR)/%: $(SOURCE_DIR)/%.dk
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) $(builddir)/dakota.project
	$(DAKOTA) --project $(builddir)/dakota.project $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(opts) --output $@ $?

$(SOURCE_DIR)/lib%.$(so_ext): $(SOURCE_DIR)/%.dk
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) $(builddir)/dakota.project
	$(DAKOTA) --project $(builddir)/dakota.project $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(opts) --soname $(soname) --shared --output $@ $?

$(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/%.json: $(SOURCE_DIR)/../lib/dakota/%.json
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/%.pm: $(SOURCE_DIR)/../lib/dakota/%.pm
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/%.json: $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/%-$(platform).json
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

$(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/%: $(DESTDIR)$(INSTALL_PREFIX)/lib/dakota/%-$(compiler)
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

$(DESTDIR)$(INSTALL_PREFIX)/lib/%.$(so_ext): $(SOURCE_DIR)/%.$(so_ext)
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(INSTALL_PREFIX)/include/%: $(SOURCE_DIR)/../include/%
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(INSTALL_PREFIX)/include/%: $(SOURCE_DIR)/%
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(INSTALL_PREFIX)/bin/%: $(SOURCE_DIR)/../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)

$(DESTDIR)$(INSTALL_PREFIX)/bin/%: $(SOURCE_DIR)/%
	sudo $(INSTALL_PROGRAM) $< $(@D)
