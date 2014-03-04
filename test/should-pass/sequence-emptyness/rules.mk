%.dot.ps: %.dot
	dot -Tps2 -o $(@) $(<)
