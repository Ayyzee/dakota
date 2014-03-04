; -*- mode: Emacs-Lisp -*-

(setq c-basic-offset 2)
(setq tab-width 2)
(setq indent-tabs-mode nil)

(global-font-lock-mode t)

(setq c++-font-lock-extra-types '("\\<\\(\\w+::?\\)*\\w+-t\\>"
				  "\\<\\(\\w+::?\\)*\\w+_t\\>"))

(font-lock-add-keywords 'c++-mode '(("\\<\\(make\\|dk::?\\w+\\)\\>"
				     . font-lock-builtin-face)))
(font-lock-add-keywords 'c++-mode '(("\\<\\(self\\|klass\\|super\\|null\\)\\>"
				     . font-lock-keyword-face)))
(font-lock-add-keywords 'c++-mode '(("\\<\\(finally\\)\\>"
				     . font-lock-keyword-face)))
(font-lock-add-keywords 'c++-mode '(("\\<\\(__import\\|__export\\|__noexport\\)\\>"
				     . font-lock-keyword-face)))
(font-lock-add-keywords 'c++-mode '(("\\<\\(__generic\\|__method\\)\\>"
				     . font-lock-keyword-face)))
(font-lock-add-keywords 'c++-mode '(("\\<\\(__selector\\|__alias\\)\\>"
				     . font-lock-function-name-face)))
(font-lock-add-keywords 'c++-mode '(("\\<\\(__klass\\|__trait\\)\\>"
				     . font-lock-keyword-face)))
(font-lock-add-keywords 'c++-mode '(("\\<\\(__superklass\\|__klass\\|__trait\\|__require\\|__provide\\|__slots\\)\\>"
				     . font-lock-keyword-face)))

(defconst c-Dakota-extra-toplevel-key "\\(namespace\\|__klass\\|__trait\\)")

(define-derived-mode dakota-mode c++-mode "Dakota"
  "Major mode for editing Dakota source files."

  (setq c-extra-toplevel-key c-Dakota-extra-toplevel-key)
  (modify-syntax-entry ?- "w")

  (c-set-offset 'label '+)
  (c-set-offset 'block-open 0)
  (c-set-offset 'substatement-open 0)
  (c-set-offset 'case-label '+)
  (c-set-offset 'statement-case-open 0)
)

(provide 'dakota-mode)

(add-hook 'dakota-mode-hook #'dakota-mode-font-lock)

(setq auto-mode-alist (cons '("\.cc$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.dk$" . dakota-mode) auto-mode-alist))
