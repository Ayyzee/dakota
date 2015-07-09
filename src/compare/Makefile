so_ext=dylib

.PHONY: all clean

all:
	cp ../obj/dakota/lib/libdakota.{$(so_ext).rep,rep} .
	mv libdakota.$(so_ext).rep libdakota-$(so_ext).rep
	./compare.pl libdakota.rep libdakota-$(so_ext).rep
	../../bin/dakota-json-flatten libdakota-trimmed.rep > libdakota-trimmed-flattened.json
	../../bin/dakota-json-flatten libdakota-$(so_ext)-trimmed.rep > libdakota-$(so_ext)-trimmed-flattened.json

diff:
	$@ libdakota-trimmed.rep libdakota-$(so_ext)-trimmed.rep

opendiff: all
	$@ libdakota-trimmed-flattened.json libdakota-$(so_ext)-trimmed-flattened.json

clean:
	rm -f libdakota.{$(so_ext).rep,rep}
	rm -f libdakota-$(so_ext).rep
	echo
	rm -f libdakota-$(so_ext)-trimmed.rep libdakota-$(so_ext)-trimmed-flattened.json
	rm -f libdakota-trimmed.rep libdakota-trimmed-flattened.json
