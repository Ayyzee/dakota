all: diff
	g++ -c -Wall -std=c++11 -o finally.o finally.hh
	g++    -Wall -std=c++11 -o example example.dk.cc

diff:
	diff example.dk example.dk.cc || true

run: all
	./example

clean:
	rm -f example finally.o *~
