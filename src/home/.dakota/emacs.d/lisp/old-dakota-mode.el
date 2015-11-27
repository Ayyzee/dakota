; -*- mode: Emacs-Lisp -*-

; how can we do this inside the (define-derived-mode dakota-mode ...)?
(setq c++-font-lock-extra-types 
      '("\\<\\(\\w+::?\\)*\\w+-t\\>"
        "\\<\\(\\w+::?\\)*\\w+_t\\>"))

(define-derived-mode dakota-mode c++-mode "Dakota"
  "Major mode for editing Dakota source files."
  (modify-syntax-entry ?- "w")
  ;(run-hooks 'dakota-mode-hook)
)
(provide 'dakota-mode)

(setq auto-mode-alist (cons '("\.dk$" . dakota-mode) auto-mode-alist))

(defun dakota-font-lock-setup ()
  ""
  (font-lock-add-keywords 'dakota-mode
                          '(("\\<\\(module\\|klass\\|trait\\)\\>" . font-lock-builtin-face)))
  (font-lock-add-keywords 'dakota-mode
                          '(("\\<\\(make\\|dk::?\\w+\\)\\>" . font-lock-builtin-face)))
  ;(setq font-lock-maximum-decoration 3)
  ;(setq font-lock-mode 3)
)
(add-hook 'dakota-mode-hook 'dakota-font-lock-setup)
