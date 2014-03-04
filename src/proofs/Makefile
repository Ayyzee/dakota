# order of dirs is not significant
dirs := $(dir $(wildcard */Makefile))

all check install uninstall clean:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done
