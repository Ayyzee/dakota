all: no-common common

no-common:
	g++ -o $@ -Wall -fno-common *.cc

common:
	g++ -o $@ -Wall *.cc

common-libs:
	g++ -dynamiclib -o 

clean:
	rm -rf no-common common *~
