all:
	g++ --compile -fPIC --all-warnings --debug=3 --output thing.o thing.cc
	g++ -dynamiclib --all-warnings --debug=3 --output libthing.$(SO_EXT) thing.o
	g++ --all-warnings --debug=3 --output thing-main thing-main.cc
	./thing-main libthing.$(SO_EXT) aaa bbb ccc

clean:
	rm -f thing.o libthing.$(SO_EXT) thing-main.o thing-main *~
