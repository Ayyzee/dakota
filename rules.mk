$(blddir)/%.dk: $(objdir)/%.tbl
$(objdir)/%.tbl: $(srcdir)/%.sh
	./$<

$(srcdir)/%.dk: $(srcdir)/%.pl
	./$< > $@

CXX_INCLUDE_DIRECTORY_FLAGS := --include-directory

$(blddir)/../bin/%: $(srcdir)/%-main.cc
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) $(srcdir)/../include $(CXX_OUTPUT_FLAGS) $@ $^
$(blddir)/%: $(srcdir)/%-main.cc
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) $(srcdir)/../include $(CXX_OUTPUT_FLAGS) $@ $^

$(blddir)/../bin/%: $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) --output $@ $(libs) $(srcs)
$(blddir)/%: $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --include-directory $(srcdir)/../include --output $@ $^

$(blddir)/../lib/%.$(so_ext):
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) --soname $(soname) --output $@ $(libs) $(srcs)

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
