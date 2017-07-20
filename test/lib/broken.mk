all:
	$(MAKE) $(MAKEFLAGS) all
	rm -fr build-dkt
	../../bin/dakota --shared --project l1.project; find build-dkt -type f | sort

#	DK_TARGET_COMMON_HEADER=0	../../bin/dakota --shared --project l1.project --define-macro DK_TARGET_COMMON_HEADER=1; find build-dkt -type f | sort
