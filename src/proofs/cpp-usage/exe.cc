#define TRAIT namespace
#define TRAIT(t)

#define KLASS namespace
#define KLASS(k)

int main()
{
  TRAIT foo { TRAIT(print) }
  KLASS bar { KLASS(kls)   }
  
  return 0;
}
