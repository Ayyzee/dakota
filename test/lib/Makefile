rootdir := ../..

DAKOTA-BASE := $(rootdir)/bin/dakota
RM := rm
RMFLAGS := -fr

.PRECIOUS: %.dk %.project

.PHONY:\
 all\
 check\
 clean\
 no-project\

so_ext := dylib
target-base := l1
target := lib$(target-base).$(so_ext)
target.project := $(target-base).project

all: $(target)

$(target-base).dk: 
	echo "klass hashed-table; func foobar() -> int-t; func foobar() -> int-t { object-t o = make(hashed-table::klass); USE(o); return 0; }" > $@

$(target.project): $(target-base).dk
	$(DAKOTA-BASE) --create-project $@ --output $(target) $^

$(target): $(target-base).dk | $(target.project)
	$(DAKOTA-BASE) --shared --project $(target.project) $^

no-project: $(target-base).dk
	$(DAKOTA-BASE) --shared $^

check: all
	$(rootdir)/bin/dakota-catalog $(target)

clean:
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build builddir --build $(target.project))
	$(RM) $(RMFLAGS) $$($(rootdir)/bin/dakota-build target   --build $(target.project))
	$(RM) $(RMFLAGS) $(target.project)
	$(RM) $(RMFLAGS) $(target-base).dk
