all:
	g++ -c -fPIC -Wall -g3 thing.cc
	g++ -dynamiclib -Wall -g3 -o libthing.$(SO_EXT) thing.o
	g++ -Wall -g3 -o thing-main thing-main.cc
	./thing-main libthing.$(SO_EXT) aaa bbb ccc

clean:
	rm -f thing.o libthing.$(SO_EXT) thing-main.o thing-main *~
