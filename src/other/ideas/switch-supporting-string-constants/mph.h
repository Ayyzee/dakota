#ifndef __MPH_H__
#define __MPH_H__

#include <stdlib.h>

#ifndef PURE
#define PURE __attribute__((pure))
#endif

#ifdef __cplusplus
namespace mph
{
struct slots_t
#else
struct mph_t
#endif
{
  unsigned int     (*hash)(const char* str);
  unsigned int       fail;
  unsigned int       base;
  unsigned int       strs_len;  
  const char* const* strs;
};
#ifdef __cplusplus
}
typedef struct mph::slots_t mph_t;
#else
typedef struct mph_t mph_t;
#endif

#ifdef __cplusplus
namespace mph {
inline PURE const char*     str(const mph_t* mph, unsigned int val)
#else
inline PURE const char* mph_str(const mph_t* mph, unsigned int val)
#endif
{
  if (val == mph->fail ||
      val <  mph->base ||
      val >  mph->base + mph->strs_len)
    return nullptr;
  return mph->strs[val - mph->base];
}
#ifdef __cplusplus
}
#endif

#endif
