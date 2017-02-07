rootdir := ../..

DAKOTA-BASE := $(rootdir)/bin/dakota
RM := rm
RMFLAGS := -fr

.PRECIOUS: %.dk %.project

.PHONY:\
 all\
 check\
 check-exe\
 clean\

target-base := exe
target := $(target-base)

all: $(target)

$(target-base).dk: 
	echo "# include \"test.hh\"" > $@
	echo "klass sorted-table; func main() -> int-t { object-t o = \$$make(sorted-table::klass()); USE(o); EXIT(0); }" >> $@

dakota.project: $(target-base).dk
	$(DAKOTA-BASE) --create-project $@ --output $(target) $^

$(target): $(target-base).dk | dakota.project
	$(DAKOTA-BASE) --project dakota.project $^

no-project: $(target-base).dk
	$(DAKOTA-BASE) $^

check check-exe: all
	./$(target)

clean:
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build builddir --build dakota.project)
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build target   --build dakota.project)
	$(RM) $(RMFLAGS) dakota.project
	$(RM) $(RMFLAGS) $(target-base).dk
	$(RM) $(RMFLAGS) $(target)
