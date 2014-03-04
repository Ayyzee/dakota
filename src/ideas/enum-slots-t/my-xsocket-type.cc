// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

/*export*/ #include <sys/socket.h>

/*export*/ namespace my-xsocket-type
{
  /*export*/ enum slots-t
  {
    k-stream = SOCK-STREAM,
    k-dgram =  SOCK-DGRAM,
    k-raw =    SOCK-RAW
  }
}
typedef my-xsocket-type:slots-t my-xsocket-type-t;

/*export*/ namespace my-point
{
  /*export*/ struct slots-t
  {
    int-t x;
    int-t y;
  }
}
typedef my-point:slots-t my-point-t;

int-t main()
{
  return 0;
}
