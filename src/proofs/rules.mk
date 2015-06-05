%.png: %.dot
	$(DOT) -Tpng -o $@ $<

%:
	$(DK) --output $@ $^

bin/%:
	$(DK) --output $@ $^

%.$(so_ext):
	$(DK) --shared --output $@ $^

lib/%.$(so_ext):
	$(DK) --shared --output $@ $^

.PHONY: all check fs images clean
