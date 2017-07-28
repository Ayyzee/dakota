SHELL := /bin/bash -o errexit -o nounset -o pipefail
INSTALL_PREFIX ?= /usr/local

rootdir ?= .
dirs-cxx := dakota-dso dakota-catalog dakota-find-library
dirs-dk :=  dakota-core dakota
dirs := $(dirs-cxx) $(dirs-dk)

# dakota:              dakota-core
# dakota-core:         dakota-dso
# dakota-catalog:      dakota-dso
# dakota-find-library  dakota-dso

.PHONY: \
 all \
 all-install \
 all-install-cxx \
 all-install-dk \
 clean \
 clean-cxx \
 clean-dk \
 install \
 uninstall \

all: all-install

all-install: all-install-cxx all-install-dk
all-install-cxx:
	sudo true # so password prompt is immediate
	for dir in $(dirs-cxx); do DKT_INITIAL_WORKDIR=$(PWD) pushd $$dir; INSTALL_PREFIX=$(INSTALL_PREFIX) ./make.sh all install; popd; done
all-install-dk:
	sudo true # so password prompt is immediate
	for dir in $(dirs-dk);  do DKT_INITIAL_WORKDIR=$(PWD) pushd $$dir; INSTALL_PREFIX=$(INSTALL_PREFIX) ./make.sh all install; popd; done

clean: clean-cxx clean-dk
clean-cxx:
	for dir in $(dirs-cxx); do DKT_INITIAL_WORKDIR=$(PWD) pushd $$dir; INSTALL_PREFIX=$(INSTALL_PREFIX) ./make.sh clean; rm -fr build-cmk; ../bin/cmake-configure.sh; popd; done
clean-dk:
	$(RM) $(RMFLAGS) cmake-binary-dir.txt
	for dir in $(dirs-dk);  do DKT_INITIAL_WORKDIR=$(PWD) pushd $$dir; INSTALL_PREFIX=$(INSTALL_PREFIX) ./make.sh clean; rm -fr build-cmk build-dkt; popd; done

uninstall-cxx:
	sudo true # so password prompt is immediate
	for dir in $(dirs-cxx); do DKT_INITIAL_WORKDIR=$(PWD) pushd $$dir; INSTALL_PREFIX=$(INSTALL_PREFIX) ../bin/build-uninstall.sh; popd; done
uninstall-dk:
	sudo true # so password prompt is immediate
	for dir in $(dirs-dk);  do DKT_INITIAL_WORKDIR=$(PWD) pushd $$dir; INSTALL_PREFIX=$(INSTALL_PREFIX) ./make.sh uninstall; popd; done
uninstall: uninstall-cxx uninstall-dk

exhaustive:
	sudo true # so password prompt is immediate
	make uninstall
	make clean
	make all
	make install
