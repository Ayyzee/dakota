dirs :=\
 compiler-driver-issues\
 finally\
 initializer-order\
 klass-interposing\
 page-faulter 

all:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

check:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done

clean:
	for dir in $(dirs); do echo "cd $$dir" ; $(MAKE) --directory $$dir $@ ; done
