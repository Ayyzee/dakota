%.dk: %.sh
	./$< > $@

%.dk: %.pl
	./$< > $@

%-$(cc_ext): %-main.$(cc_ext)
	$(CXX) $(CXXFLAGS) $(EXTRA_CXXFLAGS) --output $@ $^

%: %-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^

lib-%.$(so_ext): lib-%.dk module-lib-%.dk
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --output $@ $^
