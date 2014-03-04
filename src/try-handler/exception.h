// 00: not-throw, not-handle
// 01: 
// 10: throw, not-handle
// 11: throw, handle

enum
{
  k_handle = 1 << 0,
  k_throw =  1 << 1,
};
