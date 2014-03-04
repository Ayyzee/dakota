// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

struct point_t
{
  int x;
  int y;
};

int main()
{
  int x0;
  int y0;

  //point_t s = { .x = x0, .y = y0 };
  
  const typeof(x0)& tmp_x(x0);
  const typeof(y0)& tmp_y(y0);
  point_t point = { tmp_x, tmp_y };
  
  return 0;
}
