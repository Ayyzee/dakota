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

%.inc: $(srcdir)/%.pl
	./$< > $@

%.project: %.build
	$(rootdir)/bin/dakota-build2project $< $@

$(srcdir)/lib%.$(so_ext): $(srcdir)/%.$(cc_ext)
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) dakota.project
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(cxx-opts) $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $^

$(srcdir)/%: $(srcdir)/%.$(cc_ext)
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) dakota.project
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(cxx-opts) $(CXX_OUTPUT_FLAGS) $@ $^

$(srcdir)/%: $(srcdir)/%.dk
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) dakota.project
	$(DAKOTA) --project dakota.project $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(opts) --output $@ $?

$(srcdir)/lib%.$(so_ext): $(srcdir)/%.dk
	$(MAKE) $(MAKEFLAGS) $(EXTRA_MAKEFLAGS) dakota.project
	$(DAKOTA) --project dakota.project $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(opts) --soname $(soname) --shared --output $@ $?

$(DESTDIR)$(INSTALL_LIBDIR)/dakota/%.json: $(srcdir)/../lib/dakota/%.json
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(INSTALL_LIBDIR)/dakota/%.pm: $(srcdir)/../lib/dakota/%.pm
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(INSTALL_LIBDIR)/dakota/%.json: $(DESTDIR)$(INSTALL_LIBDIR)/dakota/%-$(platform).json
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

$(DESTDIR)$(INSTALL_LIBDIR)/dakota/%: $(DESTDIR)$(INSTALL_LIBDIR)/dakota/%-$(compiler)
	cd $(dir $<);	sudo $(LN) $(LNFLAGS) $(notdir $<) $(notdir $@);

$(DESTDIR)$(INSTALL_LIBDIR)/%.$(so_ext): $(srcdir)/%.$(so_ext)
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(INSTALL_INCLUDEDIR)/%: $(srcdir)/../include/%
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(INSTALL_INCLUDEDIR)/%: $(srcdir)/%
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(INSTALL_BINDIR)/%: $(srcdir)/../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)

$(DESTDIR)$(INSTALL_BINDIR)/%: $(srcdir)/%
	sudo $(INSTALL_PROGRAM) $< $(@D)
