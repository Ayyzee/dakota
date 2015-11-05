// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <stdio.h>
# include <ctype.h>
# include <string.h>

char8-t* ops[] =
{
   "!",
   "!=",
   "#",
   "$",
   "%",
   "%=",
   "&",
   "&&",
   "&=",
   "(",
   ")",
   "*",
   "*=",
   "+",
   "++",
   "+=",
   ",",
   "-",
   "--",
   "-=",
   "->",
   ".",
   ".*",
   "...",
   "/",
   "/=",
   ":",
   "::",
   "::*",
   ";",
   "<",
   "<<",
   "<<=",
   "<=",
   "=",
   "==",
   ">",
   ">=",
   ">>",
   ">>=",
   "?",
   "@",
   "[",
   "]",
   "^",
   "^=",
   "`",
   "{",
   "|",
   "|=",
   "||",
   "}",
   "~",
   "~="
};

char8-t* studder2_ops[] = { "+", "-", "!", "=", ":", "&", "|", "<", ">" };

char8-t* studder3_ops[] = { "." };

char8-t* equal_ops[] = { "+", "-", "/", "*", "%", "!", "<", ">", "^", "~", "<<", ">>" };

char8-t* other_ops[] = { "->", ".*", "->*", "::*" };

# define foreach(i, s)   for (uint-t i = 0; i < sizeof(s)/sizeof(s[0]); i++)

int-t main()
{
  for (int-t c = '!'; c <= '~'; c++)
  {
    if (!isalnum(c)
        && '"'  != c
        && '\'' != c
        && '\\' != c
        && '_'  != c)
      printf("%c\n", c);
  }

  foreach(i, studder2_ops)
    printf("%s%s\n", studder2_ops[i], studder2_ops[i]);

  foreach(i, studder3_ops)
    printf("%s%s%s\n", studder3_ops[i], studder3_ops[i], studder3_ops[i]);

  foreach(i, equal_ops)
    printf("%s=\n", equal_ops[i]);

  foreach(s, other_ops)
    printf("%s\n", other_ops[s]);

  return 0;
}
