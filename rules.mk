ifndef macros
	macros :=
endif
ifndef include-dirs
	include-dirs :=
endif
ifndef libs
	libs :=
endif

cxx-opts = $(macros:%=$(CXX_DEFINE_MACRO_FLAGS) %) $(include-dirs:%=$(CXX_INCLUDE_DIRECTORY_FLAGS) %) $(libs:%=$(CXX_LIBRARY_FLAGS) %)
opts =     $(macros:%=--define-macro %) $(include-dirs:%=--include-directory %) $(libs:%=--library %)

%.tbl: $(srcdir)/%.pl
	./$< > $@

%.project: %.build
	$(rootdir)/bin/dakota-build2project $< $@

$(srcdir)/lib%.$(so_ext): $(srcdir)/%.$(cc_ext)
	$(MAKE) dakota.project
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(cxx-opts) $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $^

$(srcdir)/%: $(srcdir)/%.$(cc_ext)
	$(MAKE) dakota.project
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(cxx-opts) $(CXX_OUTPUT_FLAGS) $@ $^

$(srcdir)/%: $(srcdir)/%.dk
	$(MAKE) dakota.project
	$(DAKOTA) --project dakota.project $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(opts) --output $@ $?

$(srcdir)/lib%.$(so_ext): $(srcdir)/%.dk
	$(MAKE) dakota.project
	$(DAKOTA) --project dakota.project $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(opts) --soname $(soname) --shared --output $@ $?

$(DESTDIR)$(prefix)/lib/dakota/%.json: $(srcdir)/../lib/dakota/%.json
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(prefix)/lib/dakota/%.pm: $(srcdir)/../lib/dakota/%.pm
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(prefix)/lib/%.$(so_ext): $(srcdir)/%.$(so_ext)
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(prefix)/include/%: $(srcdir)/../include/%
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(prefix)/include/%: $(srcdir)/%
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(prefix)/bin/%: $(srcdir)/../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)

$(DESTDIR)$(prefix)/bin/%: $(srcdir)/%
	sudo $(INSTALL_PROGRAM) $< $(@D)
