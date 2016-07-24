%.tbl: $(srcdir)/%.pl
	./$< > $@

%.project: %.build
	$(rootdir)/bin/dakota-build2project $@ $<

$(srcdir)/lib%.$(so_ext): $(srcdir)/%.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) $(srcdir)/../include $(CXX_SHARED_FLAGS) $(CXX_OUTPUT_FLAGS) $@ $(libs:%=-l%) $^

$(srcdir)/%: $(srcdir)/%.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) $(srcdir)/../include $(CXX_OUTPUT_FLAGS) $@ $(libs:%=-l%) $^

$(srcdir)/%: $(srcdir)/%.dk | default.project
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) --output $@ $(libs:%=--library %) $?

$(srcdir)/lib%.$(so_ext): $(srcdir)/%.dk | default.project
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) --soname $(soname) --shared --output $@ $(libs:%=--library %) $?

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
