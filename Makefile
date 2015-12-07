dirs := src mom/src mom/echo-server/src mom/distexec/src test examples

all: all-install

all-install:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir all install ; done

check:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

install:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

uninstall:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

clean:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

clean-config:
	rm -f config.mk config.sh include/config.h src/.gdbinit
