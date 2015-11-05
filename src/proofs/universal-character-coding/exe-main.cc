# include <wchar.h>
//#include <uchar.h>
# include <stdlib.h>
# include <string.h>
# include <locale.h>

// 0x21  !  \u0021
// 0x24  $  \u0024 special?
// 0x2e  .  \u002e
// 0x2f  /  \u002f
// 0x3a  :  \u003a
// 0x3f  ?  \u003f

int main(void) {
  // j \uxxxx k

  char16_t const * u\u0026 = u"";
  // char16_t const * c = u"0039";
  // wchar_t dest[100];
  // mbstowcs(dest, c, sizeof(dest));

  // wprintf(L"%c\n", c);
  return 0;
}
