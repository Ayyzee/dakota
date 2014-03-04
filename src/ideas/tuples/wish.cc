// summary:
//     book.title="war & peace"; book.pages=996;
//     vs
//     book={.title="war & peace", .pages=996};

// gcc -x c -std=c99 -DSTD_C99=1 -Wall -g3 wish.cc

#define use(v) (void)v

struct book_t
{
  int pages;
  const char* title;
};
typedef struct book_t book_t;

int main()
{
  {
    // succeeds
    book_t book;
    book.pages = 996;
    book.title = "war & peace";
    use(book);
  }
  
  {
    // succeeds
    book_t book = { 996, "war & peace" };
    use(book);
  }

#if defined STD_C99
  {
    // succeeds [ C99 only (not C++) ]
    book_t book = { .title = "war & peace", .pages = 996 }; 
    use(book);
  }
#endif

#if 1
  {
    // fails
    book_t book;
    book = { 996, "war & peace" };
    use(book);
  }

  {
    // fails
    book_t book;
    book = { .pages = 996, .title = "war & peace" };
    use(book);
  }
#endif
  return 0;
}
