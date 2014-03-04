#include <sys/time.h>

static float duration(timeval tv1, timeval tv2)
{
  time_t      sec = tv2.tv_sec - tv1.tv_sec;
  suseconds_t usec;
  if (tv2.tv_usec < tv1.tv_usec) {
    sec--;
    usec = (1000 * 1000) + tv2.tv_usec - tv1.tv_usec;
  }
  else
    usec = tv2.tv_usec - tv1.tv_usec;
  float dur = sec;
  dur +=  (float)usec/(1000 * 1000);
  return dur;
}
