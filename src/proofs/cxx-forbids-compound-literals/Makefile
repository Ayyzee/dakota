CXX := g++
CXXFLAGS := --all-warnings --ansi
EXTRA_CXXFLAGS :=
# adding --pedantic cause the compiler to reject use of "compound literal"
EXTRA_CXXFLAGS += --pedantic
CXX_OUTPUT_FLAG := --output

all:
	${CXX} ${CXXFLAGS} ${EXTRA_CXXFLAGS} ${CXX_OUTPUT_FLAG} exe exe.cc

check:
	./exe

clean:
	rm -f exe
