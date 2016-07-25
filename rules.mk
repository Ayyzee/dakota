%.tbl: $(srcdir)/%.pl
	./$< > $@

%.project: %.build
	$(rootdir)/bin/dakota-build2project $@ $<

$(srcdir)/lib%.$(so_ext): $(srcdir)/%.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) $(srcdir)/../include $(libs:%=-l%) $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $^

$(srcdir)/%: $(srcdir)/%.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) $(srcdir)/../include $(libs:%=-l%) $(CXX_OUTPUT_FLAGS) $@ $^

$(srcdir)/%: $(srcdir)/%.dk
	$(MAKE) default.project
	$(DAKOTA) --project default.project $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) $(libs:%=--library %) --output $@ $?

$(srcdir)/lib%.$(so_ext): $(srcdir)/%.dk
	$(MAKE) default.project
	$(DAKOTA) --project default.project $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) $(libs:%=--library %) --soname $(soname) --shared --output $@ $?

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
