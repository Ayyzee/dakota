all:
	clang++ --compile -fPIC lib-1.cc lib-2.cc
	clang++ --shared --output lib-shared.so lib-1.o lib-2.o
	clang++ -dynamiclib --output lib.dylib lib-1.o lib-2.o
	file *.so *.dylib
	sum *.so *.dylib

clean:
	rm -f lib-{1,2}.o lib-shared.so lib.dylib
