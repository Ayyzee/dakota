CXX := g++
CXXFLAGS := --all-warnings --ansi
EXTRA_CXXFLAGS :=
# adding --pedantic cause the compiler to reject use of "compound literal"
#EXTRA_CXXFLAGS += --pedantic
CXX_OUTPUT_FLAG := --output

all:
	${CXX} ${CXXFLAGS} ${EXTRA_CXXFLAGS} ${CXX_OUTPUT_FLAG} exe-cc exe-main.cc

check:
	./exe-cc

clean:
	rm -f exe-cc
