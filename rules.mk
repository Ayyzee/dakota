%.tbl: $(srcdir)/%.pl
	./$< > $@

../bin/%: $(srcdir)/%.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) $(CXX_INCLUDE_DIRECTORY_FLAGS) $(srcdir)/../include $(CXX_OUTPUT_FLAGS) $@ $(libs:lib%.$(so_ext)=-l%) $^

%.project: %.build
	$(rootdir)/bin/dakota-build2project $@ $<

../bin/%: | %.project
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) --project $(project) --output $@ $(libs:%=--library %) $?

../lib/lib%.$(so_ext): | %.project
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) $(macros) $(include-dirs) --project $(project) --soname $(soname) --output $@ $(libs:%=--library %) $?

$(DESTDIR)$(prefix)/lib/dakota/%.json: ../lib/dakota/%.json
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(prefix)/lib/dakota/%.pm: ../lib/dakota/%.pm
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(prefix)/lib/%.$(so_ext): ../lib/%.$(so_ext)
	sudo $(INSTALL_LIB) $< $(@D)

$(DESTDIR)$(prefix)/include/%: ../include/%
	sudo $(INSTALL_DATA) $< $(@D)

$(DESTDIR)$(prefix)/bin/%: ../bin/%
	sudo $(INSTALL_PROGRAM) $< $(@D)
