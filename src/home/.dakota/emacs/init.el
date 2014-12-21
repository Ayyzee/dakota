(setq c-basic-offset 2)
(setq tab-width 2)
(setq indent-tabs-mode nil)

; C-c C-s (c-show-syntactic-information)

; add support for which-function-mode (requires imenu support)

;`c-keywords' is set to a regexp matching all keywords in the current language
;
; namespace-open
; namespace-close
; innamespace

; adds to c-offset-alist
(c-set-offset 'label '+)
(c-set-offset 'block-open 0)
(c-set-offset 'substatement-open 0)
(c-set-offset 'case-label '+)
(c-set-offset 'statement-case-open 0)

(setq auto-mode-alist (cons '("\.dk$"   . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.ctlg$" . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.cc$"   . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.h$"    . c++-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\.dot$"    . c++-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\.rep$"  . perl-mode) auto-mode-alist))

(setq auto-mode-alist (cons '("\.sh$"  . sh-mode) auto-mode-alist))

;;; Pre-Dakota mode setup for cc-mode

(defconst c-Dakota-extra-toplevel-key "\\(extern\\|namespace\\|klass\\|trait\\)")

(defun klc:pre-dakota-mode ()
  (setq c-extra-toplevel-key c-Dakota-extra-toplevel-key)
  (modify-syntax-entry ?- "w")
)

(add-hook 'c-mode-common-hook #'klc:pre-dakota-mode)

;;; fully qualified types
(setq c++-font-lock-extra-types '("\\<\\(\\w+::?\\)*\\w+-t\\>"
				  "\\<\\(\\w+::?\\)*\\w+_t\\>"))

; font-lock-builtin-face	   font-lock-comment-face
; font-lock-constant-face	   font-lock-doc-face
; font-lock-function-name-face	   font-lock-keyword-face
; font-lock-string-face		   font-lock-type-face
; font-lock-variable-name-face	   font-lock-warning-face

;;; generic function use
(font-lock-add-keywords 'c++-mode '(("\\<\\(box\\|make\\|dk::?\\w+\\)\\>" . font-lock-builtin-face)))

;;; initialize(), make(), self, klass, super, null
(font-lock-add-keywords 'c++-mode '(("\\<\\(self\\|klass\\|super\\|null\\)\\>" . font-lock-keyword-face)))

;;; should be part of C++ :-(
(font-lock-add-keywords 'c++-mode '(("\\<\\(throw-object\\|finally\\|unless\\|until\\|else-if\\)\\>" . font-lock-keyword-face)))

;;; visiblity keywords
(font-lock-add-keywords 'c++-mode '(("\\<\\(import\\|export\\|noexport\\)\\>" . font-lock-keyword-face)))

;;; keyword
(font-lock-add-keywords 'c++-mode '(("\\<\\(generic\\|method\\)\\>" . font-lock-keyword-face)))

;;; macro()
(font-lock-add-keywords 'c++-mode '(("\\<\\(selector\\|alias\\)\\>" . font-lock-function-name-face)))

;; these two (below) have overlapping sets

;;; could be (should be?) with ... -extra-toplevel-key
(font-lock-add-keywords 'c++-mode '(("\\<\\(klass\\|trait\\)\\>" . font-lock-keyword-face)))

;;; keyword in klass | trait scope
(font-lock-add-keywords 'c++-mode '(("\\<\\(superklass\\|klass\\|trait\\|require\\|provide\\|slots\\)\\>"
                                    . font-lock-keyword-face)))
