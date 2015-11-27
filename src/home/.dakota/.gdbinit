define dk-dump-info
  call (void)'named_info_node::dump'($arg0)
end

define dk-dump
  call (void)'dk::dump'($arg0)
end

define dk-dump-methods
  call (void)'dk_dump_methods'($arg0)
end

define dk-unbox
  if 'object::instancep'($arg0, klass)
    print *unbox($arg0)
  end
end

define dk-info
  dk-dump $arg0
  dk-unbox $arg0
end

# step-generic-super
define step-generic-super
end

# step-generic-super-ka
define step-generic-super-ka
end

# step-generic
define step-generic
  step
  next
  next
  tbreak *_func_
  continue
end

# step-generic-ka
define step-generic-ka
  step
  next
  tbreak *_func_
  continue
  next
  next
  next
  tbreak *_func_
  continue
  next
  next
  tbreak *_func_
  continue
end

# step-make
define step-make
  step
  next
  tbreak *_func_
  continue
  next
  next
  next
  tbreak *_func_
  continue
  next
  next
  tbreak *_func_
  continue
end

# print-signature
define print-signature
  printf "%s %s(%s)\n", __method__->return_type, __method__->name, __method__->parameter_types
end
