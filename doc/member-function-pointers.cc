// -*- mode: C++; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// http://www.codeproject.com/cpp/FastDelegate.asp

class SomeClass
{
  public:
    float member_func(int, char*)
    {
      return 0.0;
    }
};

int main()
{
  float (SomeClass::*my_member_func)(int, char *);
  // For const member functions, it's declared like this:
  //float (SomeClass::*my_const_member_func)(int, char *) const;

  my_member_func = &SomeClass::member_func;
  // This is the syntax for operators:
  //my_member_func = &SomeClass::operator !;
  // There is no way to take the address of a constructor or destructor

  SomeClass *x = new SomeClass;
  (x->*my_member_func)(6, "Another Arbitrary Parameter");
  // You can also use the .* operator if your class is on the stack.
  SomeClass y;
  (y.*my_member_func)(15, "Different parameters this time");

  return 0;
}

