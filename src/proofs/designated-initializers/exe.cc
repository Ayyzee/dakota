struct point_t {
  int x;
  int y;
};

int main()
{
  point_t p1 =    {   .y = 5,   .x = 3, };
//point_t p1 =    { p1.y = 5, p1.x = 3, };
//point_t p2;       p2.y = 5; p2.x = 3;
//point_t p3 = {};  p3.y = 5; p3.x = 3;
//point_t p4   {};  p4.y = 5; p4.x = 3;

// ?ident = { .?ident = ?expr ${ , .?ident = ?expr }* }

  return 0;
}
