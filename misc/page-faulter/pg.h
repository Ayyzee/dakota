#include <stdlib.h> // size_t

void* pg_malloc(size_t size);
void pg_guard_read(void* addr);
void pg_guard_write(void* addr);

