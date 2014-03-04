all: $(name)

$(name): $(files)

check: all
	make fs

fs:
	rm -rf obj/usr
	find obj -type f

images: $(png_files)

clean:
	rm -rf obj lib bin
	rm -f exe *.$(SO_EXT) *.png *~
	rm -f $$DK_DEPENDS_OUTPUT_FILE
