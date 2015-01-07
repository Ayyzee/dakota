// g++ --ansi --pedantic --output exe exe.cc

struct point_t {
  int x;
  int y;
};

int main()
{
  point_t p = {  .y = 5,  .x = 3 };
//point_t p;    p.y = 5; p.x = 3;

// ?ident = { .?ident = ?expr ${ , .?ident = ?expr }* }

  return 0;
}
