
;; Dakota adds only a few primitive types
(c-lang-defconst c-primitive-type-kwds
  dakota (append
          '("symbol_t"
            "selector_t"
            "slots_t"
            "hash_t"
            "keyword_t"
            )
          ;; Use append to not be destructive on the
          ;; return value below.
          (append
           ;; Due to the fallback to C++, we need not give
           ;; a language to `c-lang-const'.
           (c-lang-const c-primitive-type-kwds)
           nil)))
