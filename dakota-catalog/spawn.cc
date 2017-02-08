// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// Copyright (C) 2007 - 2017 Robert Nielsen <robert@dakota.org>
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

# define FUNC auto

// similiar to add-nonblock in fd.dk
static FUNC
add_nonblock(int fd) -> int {
  int flags, n;
  flags = n = fcntl(fd, F_GETFL, 0);
  if (n != -1) {
    flags |= O_NONBLOCK;
    n = fcntl(fd, F_SETFL, flags);
  }
  return n;
}
static FUNC
spawn(const char* arg) -> int {
  int errno_pipe[2];
  pipe(errno_pipe);
  char child_errno_str[3 + (1)] = "";
  pid_t pid = fork();
  if (pid == -1)
    return -1;

  if (pid == 0) { // child
    close(errno_pipe[0]); // close read side of pipe
    char* args[] = { const_cast<char*>(arg), nullptr };
    execv(args[0], args);
    // execv() return ONLY on failure, so ...
    ssize_t n;
    n = snprintf(child_errno_str, sizeof(child_errno_str), "%*i", cast(int)sizeof(child_errno_str) - 1, errno);
    assert(sizeof(child_errno_str) - 1 == n);
    n = write(errno_pipe[1], child_errno_str, sizeof(child_errno_str) - 1);
    assert(sizeof(child_errno_str) - 1 == n);
    exit(EXIT_FAILURE); // execv() returns on on failure
  } else { // parent
    close(errno_pipe[1]); // close write side of pipe
    int status;
    int child_pid = waitpid(pid, &status, 0);
    if (child_pid == -1)
      return -1;
    if (WIFEXITED(status)) {
      int exit_status = WEXITSTATUS(status);
      if (exit_status != EXIT_SUCCESS) {
        ssize_t n;
        n = add_nonblock(errno_pipe[0]);
        if (n == -1)
          std::abort();
        n = read(errno_pipe[0], child_errno_str, sizeof(child_errno_str) - 1);
        if (n != -1) {
          if (n == sizeof(child_errno_str) - 1) {
            child_errno_str[sizeof(child_errno_str) - 1] = NUL;
            int child_errno;
            sscanf(child_errno_str, "%i", &child_errno);
            errno = child_errno;
            return -1;
          }
          else // we expect exactly sizeof(child_errno_str) - 1 bytes
            std::abort();
        }
        else if (errno != EAGAIN)
          std::abort();
      }
      return exit_status;
    }
    else if (WIFSIGNALED(status)) { // needed for x86-64-linux 2.6.20-15
      int sig = WTERMSIG(status);
      if (sig == SIGSEGV)
        errno = ENOEXEC;
      return -1;
    }
    else
      std::abort();
  }
}
