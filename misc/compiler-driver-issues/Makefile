all:
	$(MAKE) --directory same-library-name -f Makefile-lib $@
	$(MAKE) --directory same-executable-name -f Makefile-bin $@
	$(MAKE) --directory same-library-name $@
	$(MAKE) --directory same-executable-name $@

clean:
	$(MAKE) --directory same-library-name $@
	$(MAKE) --directory same-executable-name $@
	$(MAKE) --directory same-library-name $@
	$(MAKE) --directory same-executable-name $@
	rm -f *~
