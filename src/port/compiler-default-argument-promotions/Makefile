rootdir := ../../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	./generate-compiler-default-argument-promotions.pl $(CXX) 2> stderr.txt
	cat summary.txt

install: all
	$(CP) $(CPFLAGS) compiler-default-argument-promotions.json $(rootdir)/lib/dakota

clean:
	$(RM) $(RMFLAGS) type-index stderr.txt summary.txt
	$(RM) $(RMFLAGS) compiler-default-argument-promotions.json
	$(RM) $(RMFLAGS) obj
