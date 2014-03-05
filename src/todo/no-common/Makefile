all: no-common common

no-common:
	g++ --all-warnings -fno-common --output $@ *.cc

common:
	g++ --all-warnings --output $@ *.cc

common-libs:
	g++ -dynamiclib --output 

clean:
	rm -rf no-common common *~
