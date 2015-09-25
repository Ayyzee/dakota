// similiar to add-nonblock in fd.dk
static int
add_nonblock(int fd) {
  int flags, n;
  flags = n = fcntl(fd, F_GETFL, 0);
  if (-1 != n) {
    flags |= O_NONBLOCK;
    n = fcntl(fd, F_SETFL, flags);
  }
  return n;
}
static int
spawn(const char* arg) {
  int errno_pipe[2];
  pipe(errno_pipe);
  char child_errno_str[3 + (1)] = "";
  pid_t pid = fork();
  if (-1 == pid) return -1;
  
  if (0 == pid)
  { // child
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
  }
  else
  { // parent
    close(errno_pipe[1]); // close write side of pipe
    int status;
    int child_pid = waitpid(pid, &status, 0);
    if (-1 == child_pid) return -1;
    if (WIFEXITED(status)) {
      int exit_status = WEXITSTATUS(status);
      if (EXIT_SUCCESS != exit_status) {
	ssize_t n;
	n = add_nonblock(errno_pipe[0]);
	if (-1 == n) std::abort();
	n = read(errno_pipe[0], child_errno_str, sizeof(child_errno_str) - 1);
	if (-1 != n) {
	  if (sizeof(child_errno_str) - 1 == n) {
	    child_errno_str[sizeof(child_errno_str) - 1] = NUL;
	    int child_errno;
	    sscanf(child_errno_str, "%i", &child_errno);
	    errno = child_errno;
	    return -1;
	  }
	  else // we expect exactly sizeof(child_errno_str) - 1 bytes
	    std::abort();
	}
	else if (EAGAIN != errno)
	  std::abort();
      }
      return exit_status;
    }
    else if (WIFSIGNALED(status))
    { // needed for x86-64-linux 2.6.20-15
      int sig = WTERMSIG(status);
      if (SIGSEGV == sig)
	errno = ENOEXEC;
      return -1;
    }
    else
      std::abort();
  }
}
