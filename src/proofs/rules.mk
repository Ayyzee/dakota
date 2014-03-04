%.png: %.dot
	$(DOT) -Tpng -o $@ $<

%:
	$(DAKOTA) --output $@ $^

bin/%:
	$(DAKOTA) --output $@ $^

%.$(SO_EXT):
	$(DAKOTA) --shared --output $@ $^

lib/%.$(SO_EXT):
	$(DAKOTA) --shared --output $@ $^

.PHONY: all check fs images clean
