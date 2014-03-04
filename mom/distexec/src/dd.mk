SHELL := /bin/bash -u

include config.mk

distexec_dk_files :=\
 callback.dk\
 common.dk\
 compat-epoll.dk\
 compat-getprogname.dk\
 connection-for-msg-id.dk\
 connection.dk\
 context.dk\
 error.dk\
 event-queue.dk\
 event.dk\
 handler.dk\
 inet.dk\
 iomux.dk\
 log.dk\
 msg-id.dk\
 msg.dk\
 process.dk\
 proxy-lc.dk\
 recruiter-ls.dk\
 recruiter-us.dk\
 recruiter.dk\
 sys.dk\
 unnamed-pipe.dk\
 util.dk\
 volunteer-ms.dk\
 volunteer-uc.dk\
 volunteer.dk\
 work-queue.dk\
 work.dk\

DAKOTA := dakota
DAKOTAFLAGS := 

export CXXFLAGS := -Wall -g -w

bin/%: %-main.dk
	$(DAKOTA) $(DAKOTAFLAGS) --output $@ $^ /usr/local/lib/libdakota-util.$(SO_EXT)

all: bin/distexecd bin/distexec

bin/distexec: $(distexec_dk_files)

bin/distexecd: $(distexec_dk_files)

clean:
	rm -rf obj bin/{distexec,distexecd}
