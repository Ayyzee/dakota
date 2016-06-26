// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

# include <cstdio>
# include <cstdlib>
# include <limits>

auto main() -> int {
  bool char_is_signed = std::numeric_limits<char>::is_signed;
  bool wchar_is_signed = std::numeric_limits<wchar_t>::is_signed;

  if (char_is_signed != wchar_is_signed)
    std::abort();

  printf("%i\n", char_is_signed);
  return 0;
}
