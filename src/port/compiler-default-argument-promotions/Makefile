rootdir := ../../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

all:
	./generate-compiler-default-argument-promotions.pl $(CXX) $(rootdir)/lib/dakota/compiler-$(compiler)/default-argument-promotions.json 2> stderr.txt
	cat summary.txt

clean:
	$(RM) $(RMFLAGS) char-is-signed stderr.txt summary.txt
	$(RM) $(RMFLAGS) ../build
