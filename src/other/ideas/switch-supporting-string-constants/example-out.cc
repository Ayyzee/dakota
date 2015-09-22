typedef int (*mph_t)(const char*);

namespace __mph
{
  int _fred00pebbles00wilma00(const char*);
  int _bamm_bamm00barney00betty00(const char*);
}

void some_func(int)
{
  const char* flintstone = "some first name";
  //
  switch (__mph::_fred00pebbles00wilma00(flintstone))
  {
    case 1: /*"fred"*/
      break;
    case 3: /*"wilma"*/
      break;
    case 2: /*"pebbles*/
      break;
    default:
      ;
  }
  const char* rubble = "some first name";
  //
  switch (__mph::_bamm_bamm00barney00betty00(rubble))
  {
    case 2: /*$barney*/
      break;
    case 3: /*$betty*/
      break;
    case 1: /*$bamm-bamm*/
      break;
    default:
      ;
  }
}
