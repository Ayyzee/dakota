export EXTRA_LDFLAGS

export DAKOTA
export DAKOTAFLAGS
export EXTRA_DAKOTAFLAGS

export CXX
export CXXFLAGS
export EXTRA_CXXFLAGS

$(blddir)/%.dk: $(objdir)/%.tbl

$(objdir)/%.tbl: $(srcdir)/%.sh
	./$<

$(blddir)/../bin/%: %-main.cc
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(include_dirs) $(CXX_OUTPUT_FLAGS) $@ $^

$(blddir)/../lib/%.$(so_ext):
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --soname $(soname) --output $@ $^

$(DESTDIR)$(prefix)/bin/%: $(srcdir)/../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)
$(DESTDIR)$(prefix)/bin/%: $(blddir)/../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)

$(DESTDIR)$(prefix)/lib/%: $(srcdir)/../lib/%
	sudo $(INSTALL_LIB) $< $(@D)
$(DESTDIR)$(prefix)/lib/%: $(blddir)/../lib/%
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(prefix)/%: $(srcdir)/../%
	sudo $(INSTALL_DATA) $< $(@D)
$(DESTDIR)$(prefix)/%: $(blddir)/../%
	sudo $(INSTALL_DATA) $< $(@D)
