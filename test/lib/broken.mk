all:
	rm -fr dkt
	../../bin/dakota --shared --project l1.project; find dkt -type f | sort
