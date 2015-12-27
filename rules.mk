$(blddir)/%.tbl: $(srcdir)/%.pl
	./$< > $@

$(blddir)/../bin/%: $(srcdir)/%.cc
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) $(srcdir)/../include $(CXX_OUTPUT_FLAGS) $@ $(libs:lib%.$(so_ext)=-l%) $^
$(blddir)/%: $(srcdir)/%.cc
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) $(srcdir)/../include $(CXX_OUTPUT_FLAGS) $@ $^

$(blddir)/../bin/%: $(srcdir)/%.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) --output $@ $(libs:%=--library %) $(srcs)
$(blddir)/%: $(srcdir)/%.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

$(blddir)/../lib/%.$(so_ext):
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) --soname $(soname) --output $@ $(libs:%=--library %) $(srcs)
$(blddir)/%.$(so_ext):
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

$(DESTDIR)$(prefix)/lib/dakota/%.json: $(srcdir)/../lib/dakota/%.json
	sudo $(INSTALL_DATA) $< $(@D)
$(DESTDIR)$(prefix)/lib/dakota/%.json: $(blddir)/../lib/dakota/%.json
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(prefix)/lib/dakota/%.pm: $(srcdir)/../lib/dakota/%.pm
	sudo $(INSTALL_LIB) $< $(@D)
$(DESTDIR)$(prefix)/lib/dakota/%.pm: $(blddir)/../lib/dakota/%.pm
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(prefix)/lib/%: $(srcdir)/../lib/%
	sudo $(INSTALL_LIB) $< $(@D)
$(DESTDIR)$(prefix)/lib/%: $(blddir)/../lib/%
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(prefix)/include/%: $(srcdir)/../include/%
	sudo $(INSTALL_DATA) $< $(@D)
$(DESTDIR)$(prefix)/include/%: $(blddir)/../include/%
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(prefix)/bin/%: $(srcdir)/../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)
$(DESTDIR)$(prefix)/bin/%: $(blddir)/../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)
