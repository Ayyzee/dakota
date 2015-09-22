# result must be defined in makefile before this file is included
rt_rep := $(patsubst %.$(so), $(objdir)/rt/%.rep, $(result))

$(objdir)/%.rep: %.dk
	rep-from-dk --output $@ $^

$(objdir)/%.rep: $(objdir)/%.ctlg
	rep-from-ctlg --output $@ $^

$(objdir)/%.ctlg: %.$(so)
	ctlg-from-so --output $@ $^

$(objdir)/rt/%.rep:
	rt-rep-from-nrt-rep --output $@ $^

# $(objdir)/rt/%.rep == $(rt_rep)
$(objdir)/rt/%.cc: $(objdir)/rt/%.rep
	rt-cc-from-rt-rep --output $@ $^

$(objdir)/nrt/%.cc: $(objdir)/%.rep
	nrt-cc-from-dk --rt-rep $(rt_rep) --output $@ $^

$(objdir)/%.cc: %.dk
	cc-from-dk --rt-rep $(rt_rep) --output $@ $^

# both nrt and rt
$(objdir)/%.$o_ext: $(objdir)/%.cc
	o-from-cc --output $@ $^

# %.$(so) == $(result)
%.$(so): $(objdir)/rt/%.$o_ext
	so-from-o --output $@ $^

# % == $(result)
%: $(objdir)/rt/%.$o_ext
	exe-from-o --output $@ $^
