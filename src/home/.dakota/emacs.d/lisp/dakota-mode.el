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
                        "else-if" ; not c++
                        "enum"
                        "extern"
                        "finally" ; not c++
                        "for"
                        "if"
                        "in"
                        "klass" ; not c++
                        "method" ; not c++
                        "module"
                        "namespace"
                        "return"
                        "slots" ; not c++
                        "static"
                        "superklass" ; not c++
                        "switch"
                        "trait" ; not c++
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
                     "ptr-t"
                     "slots-t"
                     "str-t"
                     "symbol-t"
                     "va-list-t"
                     "int-t"
                     ))
(setq dakota-constants '(
                         "NUL"
                         "__func__"
                         "__klass__"
                         "__method__"
                         "__trait__"
                         "exception::klass"
                         "false"
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
                         "SELECTOR"
                         "SIGNATURE"
                         "at?"
                         "box"
                         "cast"
                         "dk-hash"
                         "dk-intern"
                         "dk-intern-free"
                         "dk-klass-for-name"
                         "equal?"
                         "in?"
                         "klass-of"
                         "make"
                         "offsetof"
                         "sizeof"
                         "static-assert"
                         "superklass-of"
                         "typeid"
                         "unbox"
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
  "Dakota mode"
  "Major mode for editing Dakota files"
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
