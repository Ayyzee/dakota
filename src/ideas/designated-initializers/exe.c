struct point_t
{
  int x;
  int y;
};

struct point_t point()
{
#if GNU_DESIGNATED_INITIALIZER
  struct point_t p = { x : 0, y : 0 };
#else
  struct point_t p = { .x = 0, .y = 0 };
#endif
  return p;
}
