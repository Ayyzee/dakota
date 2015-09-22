all:
	g++ --compile -fPIC --all-warnings --debug=3 --output thing.o thing.cc
	g++ -dynamiclib --all-warnings --debug=3 --output libthing.$(so_ext) thing.o
	g++ --all-warnings --debug=3 --output thing-main thing-main.cc
	./thing-main libthing.$(so_ext) aaa bbb ccc

clean:
	rm -f thing.o libthing.$(so_ext) thing-main.o thing-main *~
