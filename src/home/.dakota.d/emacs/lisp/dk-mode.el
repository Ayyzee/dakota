; -*- mode: Emacs-Lisp -*-

(defvar dk-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?- "w" st)
    st)
  "Syntax table for `dk-mode'.")

;; define several category of keywords
(setq dk-keywords '(
                    "auto"
                    "break"
                    "case"
                    "const"
                    "default"
                    "do"
                    "else"
                    "enum"
                    "extern"
                    "for"
                    "if"
                    "klass"
                    "method"
                    "module"
                    "namespace"
                    "return"
                    "slots"
                    "static"
                    "switch"
                    "trait"
                    "while"
                    "void"
                    ))
(setq dk-types '(
                 "boole-t"
                 "keyword-t"
                 "object-t"
                 "slots-t"
                 "str-t"
                 "symbol-t"
                 ))
(setq dk-constants '(
                     "NUL"
                     "null"
                     "nullptr"
                     "std-error"
                     "std-input"
                     "std-output"
                     ))
(setq dk-functions '(
                     "dk-hash"
                     "dk-intern"
                     "dk-intern-free"
                     "dk-klass-for-name"
                     "klass-of"
                     "make"
                     "SELECTOR"
                     "SIGNATURE"
                     "superklass-of"
                     ))
;; generate regex string for each category of keywords
(setq dk-keywords-regexp  (regexp-opt dk-keywords  'words))
(setq dk-types-regexp     (regexp-opt dk-types     'words))
(setq dk-constants-regexp (regexp-opt dk-constants 'words))
(setq dk-functions-regexp (regexp-opt dk-functions 'words))

;; create the list for font-lock.
;; each category of keyword is given a particular face
(setq dk-font-lock-keywords
      `(
        (,dk-types-regexp     . font-lock-type-face)
        (,dk-constants-regexp . font-lock-constant-face)
        (,dk-functions-regexp . font-lock-function-name-face)
        (,dk-keywords-regexp  . font-lock-keyword-face)
        ;; note: order above matters, because once colored, that part won't change.
        ;; in general, longer words first
        ))

;;;###autoload
(define-derived-mode dk-mode c++-mode
  "dk mode"
  "Major mode for editing dk files"
  ;:syntax-table dk-mode-syntax-table ; FAILS

  ;; code for syntax highlighting
  (setq font-lock-defaults '((dk-font-lock-keywords))) ; REQUIRED
  (setq font-lock-maximum-decoration 3)
  )
;; clear memory. no longer needed
(setq dk-keywords  nil)
(setq dk-types     nil)
(setq dk-constants nil)
(setq dk-functions nil)

;; clear memory. no longer needed
(setq dk-keywords-regexp  nil)
(setq dk-types-regexp     nil)
(setq dk-constants-regexp nil)
(setq dk-functions-regexp nil)

;; add the mode to the `features' list
(provide 'dk-mode)

;;; dk-mode.el ends here
