// -*- mode: c++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// Copyright (C) 2007 - 2015 Robert Nielsen <robert@dakota.org>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <cstdio>
#include <cstdlib>
#include <csignal>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#define cast(t) (t)

[[noreturn]] static inline void
clean_abort(pid_t pid) {
  kill(pid, SIGKILL);
  int status = 0;
  waitpid(pid, &status, 0);
  std::abort();
}

[[noreturn]] static void
sigalarm_handler(int, siginfo_t* si, void*) noexcept {
  clean_abort(si->si_pid);
}

[[noreturn]] int
main(int argc, char const* const argv[]) {
  if (2 > argc)
    exit(EXIT_FAILURE);
  unsigned int secs = 0;
  sscanf(argv[1], "%u", &secs);

  int r = 0;
  struct sigaction sa = {};
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_SIGINFO;
  sa.sa_sigaction = sigalarm_handler;
  r = sigaction(SIGALRM,   &sa, nullptr); if (0 != r) std::abort();
//r = sigaction(SIGVTALRM, &sa, nullptr); if (0 != r) std::abort();

  struct itimerval tmr;
  tmr.it_value.tv_sec =     2;
  tmr.it_value.tv_usec =    0;
  tmr.it_interval.tv_sec =  0;
  tmr.it_interval.tv_usec = 0;
  r = setitimer(ITIMER_REAL, &tmr, nullptr); if (0 != r) std::abort();
//r = setitimer(ITIMER_VIRTUAL, &tmr, nullptr); if (0 != r) std::abort();

  pid_t pid = fork(); if (-1 == pid) std::abort();

  if (pid) { // parent
    int status = 0;
    r = waitpid(pid, &status, 0); if (-1 == pid) std::abort();

    if (WIFEXITED(status))
      exit(WEXITSTATUS(status));
    clean_abort(pid);
  } else { // child
    execvp(argv[2], cast(char * const*)&argv[2]); std::abort();
  }
}
