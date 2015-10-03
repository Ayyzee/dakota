typedef void* object_t;

klass deque;

// this can not exist since deque is already a scope, it can not be a function also
// but, 'deque' may be a variable inside a function scope (and potentially other scopes)
//
// object_t deque(...) { ... }

int main() {
  object_t l =  deque(3, 2, 1);
//object_t l = #deque(#3, #2, #1);
  //=>
  object_t l = make(deque, box(3), box(2), box(1), nullptr);
  //=>
  object_t l = make(deque::klass, box(3), box(2), box(1), nullptr);
  
  return 0;
}
