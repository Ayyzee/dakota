objdir := obj
so := dylib
result := lib/libresult.$(so)
rt_rep := $(patsubst %.$(so), $(objdir)/rt/%.rep, $(result))

$(objdir)/%.cc: %.dk $(rt_rep)
	echo --rt-rep $(rt_rep) --output $@ $^
	touch $@

$(objdir)/foo.cc: foo.dk

all: $(objdir)/foo.cc
