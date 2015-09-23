rootdir := ..
include $(rootdir)/config.mk

export CXXFLAGS := -g3 -Wall

name :=  $(shell dakota-project name  --var so_ext=$(so_ext))
files := $(shell dakota-project files --var so_ext=$(so_ext))

all: $(name)

$(name): $(files)
	dakota --output $@ $^

check: all
	./check.sh sample.dk

clean:
	rm -rf $(name) obj *~
