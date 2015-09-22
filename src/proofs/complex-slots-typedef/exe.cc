// -*- mode: Dakota; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: nil -*-

// http://stackoverflow.com/questions/4523497/typedef-fixed-length-array

union aa_t { int i; char* p; };
union bb_t : aa_t { k_three = 3, k_four = 4 };

typedef char char_t;
typedef int int_t;

typedef char type24[3];
// typedef ?type ?name[n]
typedef char_t str10_t[10]; // typedef char_t[10] str10_t;

// typedef ?type (*?name)(?arglist-in)
// =>
// typedef ?type (*)(?arglist-in) ?name
typedef int_t (*slots_t)(int_t, int_t);

//typedef (int_t (*)(int_t, int_t))[16] slots_t;

int main() { return 0; }
