rootdir := ../../..

include $(rootdir)/config.mk
include $(rootdir)/common.mk

DAKOTA := dakota

DAKOTAFLAGS +=\
 --include-directory=$(srcdir)/.\
 --include-directory=../include\
 --include-directory=../../include\
 --include-directory=$(rootdir)/include\

export CXXFLAGS := --all-warnings --debug=3

%$(exeext): %-main.dk
	$(DAKOTA) --output $@ $(DAKOTAFLAGS) $^ $(libdir)/$(lib_prefix)dakota-util.$(SO_EXT) $(libdir)/$(lib_prefix)dakota-mom.$(SO_EXT) $(libdir)/$(lib_prefix)dakota-x.$(SO_EXT)

include libdakota-distexec-dk-files

all: distexecd$(exeext) distexec$(exeext)
clean:
	rm -f distexecd$(exeext) distexec$(exeext) $(lib_prefix)dakota-distexec.$(SO_EXT)
	rm -rf obj
	rm -f *~
install:
uninstall:

check: $(lib_prefix)dakota-distexec.$(SO_EXT)
	dakota-introspector $^

$(lib_prefix)dakota-distexec.$(SO_EXT): $(libdakota_distexec_dk_files)
	$(DAKOTA) --shared --output $@ $(DAKOTAFLAGS) $^ $(libdir)/$(lib_prefix)dakota-util.$(SO_EXT) $(libdir)/$(lib_prefix)dakota-mom.$(SO_EXT) $(libdir)/$(lib_prefix)dakota-x.$(SO_EXT)

distexecd: $(lib_prefix)dakota-distexec.$(SO_EXT)

distexec: $(lib_prefix)dakota-distexec.$(SO_EXT)
