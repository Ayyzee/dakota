# -*- mode: makefile -*-

%.ctlg :
	dakota-catalog --output $@ $<

%.ctlg.ast : %.ctlg
	dakota --action parse --output $@ $<
