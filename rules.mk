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

CXX_INCLUDE_DIRECTORY_FLAGS := --include-directory

$(blddir)/../bin/%: $(srcdir)/%-main.cc
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) ../include $(CXX_OUTPUT_FLAGS) $@ $^
$(blddir)/%: $(srcdir)/%-main.cc
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_WARNINGS_FLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) ../include $(CXX_OUTPUT_FLAGS) $@ $^

$(blddir)/../bin/%: $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --output $@ $^
$(blddir)/%: $(srcdir)/%-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --include-directory ../include --output $@ $^

$(blddir)/../lib/%.$(so_ext):
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include_dirs) --soname $(soname) --output $@ $^
$(blddir)/%.$(so_ext):
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --include-directory ../include --output $@ $^

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
