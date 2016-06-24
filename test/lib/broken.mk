all:
	$(MAKE) $(MAKEFLAGS) all
	rm -fr dkt
	../../bin/dakota --shared --project l1.project; find dkt -type f | sort

#	DK_GENERATE_COMMON_HEADER=0	../../bin/dakota --shared --project l1.project --define-macro DK_GENERATE_COMMON_HEADER=1; find dkt -type f | sort
