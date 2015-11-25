; -*- mode: Emacs-Lisp -*-

(defvar dakota-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?- "w" st)
    st)
  "Syntax table for `dakota-mode'.")

;; define several category of keywords
(setq dakota-keywords '(
                    "auto"
                    "break"
                    "case"
                    "catch"
                    "const"
                    "default"
                    "do"
                    "else"
                    "else-if"
                    "enum"
                    "extern"
                    "finally"
                    "for"
                    "if"
                    "in"
                    "klass"
                    "method"
                    "module"
                    "namespace"
                    "return"
                    "slots"
                    "static"
                    "superklass"
                    "switch"
                    "trait"
                    "true"
                    "try"
                    "while"
                    "void"
                    ))
(setq dakota-types '(
                 "boole-t"
                 "keyword-t"
                 "method-t"
                 "object-t"
                 "slots-t"
                 "str-t"
                 "symbol-t"
                 ))
(setq dakota-constants '(
                     "false"
                     "NUL"
                     "exception::klass"
                     "klass::klass"
                     "null"
                     "nullptr"
                     "object::klass"
                     "std-error"
                     "std-input"
                     "std-output"
                     "true"
                     ))
(setq dakota-functions '(
                     "at?"
                     "SELECTOR"
                     "SIGNATURE"
                     "__func__"
                     "__klass__"
                     "__method__"
                     "__trait__"
                     "cast"
                     "dakota-hash"
                     "dakota-intern"
                     "dakota-intern-free"
                     "dakota-klass-for-name"
                     "equal?"
                     "in?"
                     "klass-of"
                     "make"
                     "offsetof"
                     "sizeof"
                     "static-assert"
                     "superklass-of"
                     "typeid"
                     ))
;; generate regex string for each category of keywords
(setq dakota-keywords-regexp  (regexp-opt dakota-keywords  'words))
(setq dakota-types-regexp     (regexp-opt dakota-types     'words))
(setq dakota-constants-regexp (regexp-opt dakota-constants 'words))
(setq dakota-functions-regexp (regexp-opt dakota-functions 'words))

;; create the list for font-lock.
;; each category of keyword is given a particular face
(setq dakota-font-lock-keywords
      `(
        (,dakota-types-regexp     . font-lock-type-face)
        (,dakota-constants-regexp . font-lock-constant-face)
        (,dakota-functions-regexp . font-lock-function-name-face)
        (,dakota-keywords-regexp  . font-lock-keyword-face)
        ;; note: order above matters, because once colored, that part won't change.
        ;; in general, longer words first
        ))

;;;###autoload
(define-derived-mode dakota-mode c++-mode
  "dakota mode"
  "Major mode for editing dakota files"
  ;:syntax-table dakota-mode-syntax-table ; FAILS

  ;; code for syntax highlighting
  (setq font-lock-defaults '((dakota-font-lock-keywords))) ; REQUIRED
  (setq font-lock-maximum-decoration 3)
  )
;; clear memory. no longer needed
(setq dakota-keywords  nil)
(setq dakota-types     nil)
(setq dakota-constants nil)
(setq dakota-functions nil)

;; clear memory. no longer needed
(setq dakota-keywords-regexp  nil)
(setq dakota-types-regexp     nil)
(setq dakota-constants-regexp nil)
(setq dakota-functions-regexp nil)

;; add the mode to the `features' list
(provide 'dakota-mode)
