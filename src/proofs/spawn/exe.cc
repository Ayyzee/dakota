#include <getopt.h> // getopt_long()
#include <dlfcn.h>  // dlopen()
#include <sys/param.h> // MAXPATHLEN
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/wait.h>
#include <assert.h>

static void
dump_status(int status)
{
    fprintf(stdout,
	  "<status=0x%x>\n"

	  "exitstatus=%i\n"
	  "termsig=%i\n"
	  "stopsig=%i\n"

	  "ifexited=%i\n"
	  "ifsignaled=%i\n"
	  "ifstopped=%i\n"

	  ,status

	  ,WEXITSTATUS(status)
	  ,WTERMSIG(status)
	  ,WSTOPSIG(status)

	  ,WIFEXITED(status)
	  ,WIFSIGNALED(status)
	  ,WIFSTOPPED(status)
	 );
    return;
}

static int
spawn(const char* arg)
{
  pid_t pid = fork();
  if (-1 == pid) return -1;
  
  if (0 == pid)
  { // child
    char* args[] = { (char*)arg, nullptr };
    execve(args[0], args, nullptr);
    fprintf(stderr, "ERROR: errno=%i, \"%s\"\n", errno, strerror(errno));
    exit(EXIT_FAILURE);
    //return -1;
  }
  else
  { // parent
    int status;
    int child_pid = waitpid(pid, &status, 0);
    if (-1 == child_pid) return -1;
    return status;
  }
}

int
main(int argc, const char* const* argv)
{
  int status = spawn(argv[1]);
  if (-1 != status)
    dump_status(status);

  if (-1 == status)
    exit(EXIT_FAILURE);
  else
    exit(EXIT_SUCCESS);
}
