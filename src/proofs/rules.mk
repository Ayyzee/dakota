%.png: %.dot
	$(DOT) -Tpng -o $@ $<

%:
	$(DK) --output $@ $^

bin/%:
	$(DK) --output $@ $^

%.$(SO_EXT):
	$(DK) --shared --output $@ $^

lib/%.$(SO_EXT):
	$(DK) --shared --output $@ $^

.PHONY: all check fs images clean
