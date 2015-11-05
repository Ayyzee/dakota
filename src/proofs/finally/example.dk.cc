# include "finally.hh"
# include <stdio.h>

int fnc1(void) {
  fprintf(stdout, "fnc1: before-finally [1]\n");

  finally __finally([&] {
    fprintf(stdout, "fnc1: inside-finally [4]\n");
  } );
  fprintf(stdout, "fnc1: after-finally [2]\n");

  return fprintf(stdout, "fnc1: before-return [3]\n");
  
  fprintf(stderr, "fnc1: after-return [NEVER]\n");
}

const char* throw_before(const char* str) {
  fprintf(stdout, "main: before-throw [3]\n");
  return str;
}

int main(void) {
  fnc1();
  fprintf(stdout, "---\n");

  try {
    fprintf(stdout, "main: before-finally [1]\n");
    const char* name = "/dev/null";
    FILE* file = fopen(name, "w");

    finally __finally([&] {
      fprintf(stdout, "main: inside-finally [4]\n");
      fclose(file);
    } );
  
    fprintf(stdout, "main: after-finally [2]\n");
  
    throw throw_before("main: inside-catch [5]");
  
    fprintf(stderr, "main: after-exception [NEVER]\n");
  }
  catch(const char *ex) {
    fprintf(stdout, "%s\n", ex);
  }
  catch(...) {
    fprintf(stdout, "main: unknown-exception [NEVER]\n");
  }
  return 0;
}
