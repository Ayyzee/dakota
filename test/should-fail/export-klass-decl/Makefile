rootdir := ../../..
include $(rootdir)/test/vars.mk

all: $(target)

$(target): $(prereq) lib-1.$(so_ext)
	$(DAKOTA) $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --include-directory=. --output $@ $^

lib-1.$(so_ext): file-1.dk file-2.dk module-lib-1.dk
	$(DAKOTA) --shared $(DAKOTAFLAGS) $(EXTRA_DAKOTAFLAGS) --include-directory=. --output $@ $^

check:
	./$(target)

clean:
	$(RM) $(RMFLAGS) obj
	$(RM) $(RMFLAGS) ./$(target) file-{1,2}.o lib-1.$(so_ext) *~
