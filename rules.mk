$(blddir)/%.tbl: $(srcdir)/%.pl
	./$< > $@

$(blddir)/../bin/%: $(srcdir)/%.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) $(srcdir)/../include $(CXX_OUTPUT_FLAGS) $@ $(libs:lib%.$(so_ext)=-l%) $^

%.project: %.build
	$(rootdir)/bin/dakota-build2project $< $* $@

$(blddir)/../bin/%:
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) --project $(project) --output $@ $(libs:%=--library %) $(srcs)

$(blddir)/../lib/%.$(so_ext):
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) --project $(project) --soname $(soname) --output $@ $(libs:%=--library %) $?

$(DESTDIR)$(prefix)/lib/dakota/%.json: $(blddir)/../lib/dakota/%.json
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(prefix)/lib/dakota/%.pm: $(blddir)/../lib/dakota/%.pm
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(prefix)/lib/%.$(so_ext): $(blddir)/../lib/%.$(so_ext)
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(prefix)/include/%: $(blddir)/../include/%
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(prefix)/bin/%: $(blddir)/../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)
