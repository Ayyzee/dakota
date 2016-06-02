rootdir := ../..

DAKOTA-BASE := $(rootdir)/bin/dakota
RM := rm
RMFLAGS := -fr

.PRECIOUS: %.dk %.project

.PHONY:\
 all\
 check\
 clean\

target-base := exe
target := $(target-base)
target.project := $(target-base).project

all: $(target)

$(target-base).dk: 
	echo "klass hashed-table; func main() -> int-t { object-t o = make(hashed-table::klass); USE(o); return 0; }" > $@

$(target.project):
	$(DAKOTA-BASE) --create-project $@ --output $(target) $(target-base).dk

$(target): $(target-base).dk $(target.project)
	$(DAKOTA-BASE) --project $(target.project) $(target-base).dk

check: all
	./$(target)

clean:
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build builddir --build $(target.project))
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build target   --build $(target.project))
	$(RM) $(RMFLAGS) $(target.project)
	$(RM) $(RMFLAGS) $(target-base).dk
