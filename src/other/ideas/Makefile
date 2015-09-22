# order of dirs is not significant
dirs := $(dir $(wildcard */Makefile))

all:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

check:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

install:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

uninstall:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

clean:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done
