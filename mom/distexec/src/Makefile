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

%: %-main.dk
	$(DAKOTA) --output $@ $(DAKOTAFLAGS) $^ $(libdir)/$(lib_prefix)dakota-util.$(so_ext) $(libdir)/$(lib_prefix)dakota-mom.$(so_ext) $(libdir)/$(lib_prefix)dakota-x.$(so_ext)

include libdakota-distexec-dk-files

all: distexecd distexec
clean:
	rm -f distexecd distexec $(lib_prefix)dakota-distexec.$(so_ext)
	rm -rf obj
	rm -f *~
install:
uninstall:

check: $(lib_prefix)dakota-distexec.$(so_ext)
	dakota-introspector $^

$(lib_prefix)dakota-distexec.$(so_ext): $(libdakota_distexec_dk_files)
	$(DAKOTA) --shared --output $@ $(DAKOTAFLAGS) $^ $(libdir)/$(lib_prefix)dakota-util.$(so_ext) $(libdir)/$(lib_prefix)dakota-mom.$(so_ext) $(libdir)/$(lib_prefix)dakota-x.$(so_ext)

distexecd: $(lib_prefix)dakota-distexec.$(so_ext)

distexec: $(lib_prefix)dakota-distexec.$(so_ext)
