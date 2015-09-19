rootdir := ../..

collections := sets counted-sets tables collection-add-all-first collection-forward-iteration

all: $(collections)
	for dir in $^; do $(MAKE) --directory $$dir all; done

check: $(collections)
	for dir in $^; do $(MAKE) --directory $$dir check; done

clean: $(collections)
	for dir in $^; do $(MAKE) --directory $$dir clean; done
