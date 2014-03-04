#if defined NAME
static const char* name = NAME;
#else
static const char* name = __FILE__;
#endif

void
dk_register(const char* lib_name);

void
dk_unregister(const char* lib_name);

__attribute__((constructor))
static
void initialize()
{
     dk_register(name);
     return;
}

__attribute__((destructor))
static
void finalize()
{
     dk_unregister(name);
     return;
}
