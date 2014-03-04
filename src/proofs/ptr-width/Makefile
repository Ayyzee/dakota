all: exe-32 exe-64

exe-32: exe.cc
	g++ -Wall exe.cc -o $@

exe-64: exe.cc
	g++ -Wall -arch x86_64 -mmacosx-version-min=10.5 exe.cc -o $@

check: exe-32 exe-64
	./exe-32
	./exe-64

clean:
	rm -f exe-32 exe-64
