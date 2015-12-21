rootdir := ../../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	CXX=$(CXX) ./generate-compiler-default-argument-promotions.pl

install: all
	$(CP) $(CPFLAGS) compiler-default-argument-promotions.json $(rootdir)/lib/dakota

clean:
	$(RM) $(RMFLAGS) type-index
	$(RM) $(RMFLAGS) compiler-default-argument-promotions.json
	$(RM) $(RMFLAGS) obj
