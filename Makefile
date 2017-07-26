SHELL := /bin/bash -o errexit -o nounset -o pipefail

rootdir ?= .
dirs-cc := dakota-dso dakota-catalog dakota-find-library
dirs-dk := dakota-core dakota
dirs := $(dirs-cc) $(dirs-dk)

# dakota:              dakota-core
# dakota-core:         dakota-catalog
#                      dakota-find-library
# dakota-catalog
# dakota-find-library: dakota-dso

.PHONY: \
 all \
 all-install \
 check \
 check-exe \
 clean \
 dist \
 distclean \
 goal-clean \
 install \
 installcheck \
 precompile \
 uninstall \

all: all-install

all-install:
	sudo true # so password prompt is immediate
	for dir in $(dirs); do DKT_INITIAL_WORKDIR=$(PWD) pushd $$dir; INSTALL_PREFIX=$${INSTALL_PREFIX-$$HOME} ./make.sh all install; popd; done

uninstall:
	for dir in $(dirs-dk) test; do DKT_INITIAL_WORKDIR=$(PWD) pushd $$dir; INSTALL_PREFIX=$${INSTALL_PREFIX-$$HOME} ./make.sh $@; popd; done
	echo warning: did not uninstall in dirs: $(dirs-cc)

check \
check-exe \
dist \
distclean \
goal-clean \
installcheck \
precompile:
	for dir in $(dirs-dk) test; do DKT_INITIAL_WORKDIR=$(PWD) pushd $$dir; INSTALL_PREFIX=$${INSTALL_PREFIX-$$HOME} ./make.sh $@; popd; done

all \
clean \
install:
	for dir in $(dirs); do DKT_INITIAL_WORKDIR=$(PWD) pushd $$dir; INSTALL_PREFIX=$${INSTALL_PREFIX-$$HOME} ./make.sh $@; popd; done
