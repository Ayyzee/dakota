all: exe-cc-32 exe-cc-64

exe-cc-32: exe-main.cc
	g++ -Wall -ansi -pedantic exe-main.cc -o $@

exe-cc-64: exe-main.cc
	g++ -Wall -ansi -pedantic -arch x86_64 -mmacosx-version-min=10.5 exe-main.cc -o $@

check: exe-cc-32 exe-cc-64
	./exe-cc-32
	./exe-cc-64

clean:
	rm -f exe-cc-32 exe-cc-64
