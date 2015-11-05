# include <stddef.h>
# include <stdlib.h>
# include <stdio.h>

namespace foo { namespace bar {
    struct slots_t
    {
      int i;
    };
}}

int main()
{
  // same
  { const struct foo::bar::slots_t   i = {0}; (void)i; }
  { struct foo::bar::slots_t const   i = {0}; (void)i; }

  // same
  { const struct foo::bar::slots_t * i = {0}; (void)i; }
  { struct foo::bar::slots_t const * i = {0}; (void)i; }

  // same
  { const struct foo::bar::slots_t * const         i = {0}; (void)i; }
  { struct foo::bar::slots_t const * const         i = {0}; (void)i; }

  // same
  { const struct foo::bar::slots_t * const * const i = {0}; (void)i; }
  { struct foo::bar::slots_t const * const * const i = {0}; (void)i; }

  // same
  { const struct foo::bar::slots_t *       i[2][2] = {0}; (void)i; }
  { struct foo::bar::slots_t const *       i[2][2] = {0}; (void)i; }

  // same
  { const struct foo::bar::slots_t * const i[2][2] = {0}; (void)i; }
  { struct foo::bar::slots_t const * const i[2][2] = {0}; (void)i; }

  { int (i)(); (void)i; }
  { int (*i)(); (void)i; }
  { int (**i)(); (void)i; }

  // wrong
  { const struct foo::bar::slots_t const * i = {0}; (void)i; }

  return 0;
}
