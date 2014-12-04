rootdir := ../../..

include $(rootdir)/config.mk
include $(rootdir)/vars.mk

DAKOTA := dakota

DAKOTAFLAGS +=\
 --include-directory=$(srcdir)/.\
 --include-directory=../include\
 --include-directory=../../include\
 --include-directory=$(rootdir)/include\

export CXXFLAGS := --all-warnings --debug=3

%$(exeext): %-main.dk
	$(DAKOTA) --output $@ $(DAKOTAFLAGS) $^ $(libdir)/$(lib_prefix)dakota-util.$(SO_EXT) $(libdir)/$(lib_prefix)dakota-mom.$(SO_EXT)

all: echo-server$(exeext) echo-client$(exeext)
clean:
	rm -f echo-server$(exeext) echo-client$(exeext)
	rm -rf obj
	rm -f *~
install:
uninstall:

dakota:
	make --directory ../../../src
dakota-clean:
	make --directory ../../../src clean
dakota-install:
	make --directory ../../../src install
dakota-uninstall:
	make --directory ../../../src uninstall

mom:
	make --directory ../../src
mom-clean:
	make --directory ../../src clean
mom-install:
	make --directory ../../src install
mom-uninstall:
	make --directory ../../src uninstall

deep:
	make dakota
	make dakota-install
	make mom
	make mom-install
	make
	make install
deep-clean:
	make dakota-clean
	make mom-clean
	make clean
deep-install:
	make dakota-install
	make mom-install
	make install
deep-uninstall:
	make dakota-uninstall
	make mom-uninstall
	make uninstall
