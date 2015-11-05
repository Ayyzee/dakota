# define cast(t) (t)

int main()
{
//int smpl = zero;
//=>
  int smpl = cast(decltype(smpl))0;

//struct { int x; int y; } agg = zero;
//=>
//struct { int x; int y; } agg = { zero, zero };
//=>
  struct { int x; int y; } agg = { cast(decltype(agg.x))0, cast(decltype(agg.x))0 };

  /*

    ?type ?ident = zero ;
      or
    { ?type ?ident ; ?type ?ident ; } ?ident = zero ;
      or
    { ?type ?ident ; ?type ?ident ; } ?ident = { zero , zero } ;

    The number of zero elements in the RHS of the aggregate might be less
    than the number of members in the LHS.

    The user may want to use 'zero' for just some of the aggregate members, so its
    not an all or nothing situation.

  */
  
  return 0;
}
