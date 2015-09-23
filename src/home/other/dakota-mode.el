; -*- mode: Emacs-Lisp -*-

;;; dakota-mode.el


;module
;klass trait
;method
;make box unbox alias selector
;generic dk:*
;superklass
;self klass super null
;std-input std-output std-error
;traits
;slots
;import export
;*-t
;unless until else-if


;;; Code:

(require 'cc-mode)

;; These are only required at compile time to get the sources for the
;; language constants.  (The cc-fonts require and the font-lock
;; related constants could additionally be put inside an
;; (eval-after-load "font-lock" ...) but then some trickery is
;; necessary to get them compiled.)
(eval-when-compile
  (require 'cc-langs)
  (require 'cc-fonts))

(eval-and-compile
  ;; Make our mode known to the language constant system.  Use C++
  ;; mode as the fallback for the constants we don't change here.
  ;; This needs to be done also at compile time since the language
  ;; constants are evaluated then.
  (c-add-language 'dakota-mode 'c++-mode))

;; Dakota replaces va_list with va_list_t (other stuff will go here eventually)
(c-lang-defconst c-primitive-type-kwds
  dakota (append '("object-t" "object_t"
                   "va-list-t" "va_list_t")
                 ;; Use append to not be destructive on the
                 ;; return value below.
                 (append
                  ;; Due to the fallback to Java, we need not give
                  ;; a language to `c-lang-const'.
                  (c-lang-const c-primitive-type-kwds)
                  nil)))

;; Method declarations begin with "method" in this language.
;; There's currently no special keyword list for that in CC Mode, but
;; treating it as a modifier works fairly well.
(c-lang-defconst c-modifier-kwds
  dakota (cons "method" (c-lang-const c-modifier-kwds)))

;(setq dakota-font-lock-extra-types
;      '("\\<\\(\\w+::?\\)*\\w+-t\\>"
;        "\\<\\(\\w+::?\\)*\\w+_t\\>"))

(defcustom dakota-font-lock-extra-types nil
  "*List of extra types (aside from the type keywords) to recognize in Dakota mode.
Each list item should be a regexp matching a single identifier.")

(defconst dakota-font-lock-keywords-1 (c-lang-const c-matchers-1 dakota)
  "Minimal highlighting for Dakota mode.")

(defconst dakota-font-lock-keywords-2 (c-lang-const c-matchers-2 dakota)
  "Fast normal highlighting for Dakota mode.")

(defconst dakota-font-lock-keywords-3 (c-lang-const c-matchers-3 dakota)
  "Accurate normal highlighting for Dakota mode.")

(defvar dakota-font-lock-keywords dakota-font-lock-keywords-3
  "Default expressions to highlight in Dakota mode.")

(defvar dakota-mode-syntax-table nil
  "Syntax table used in dakota-mode buffers.")
(or dakota-mode-syntax-table
    (setq dakota-mode-syntax-table
	  (funcall (c-lang-const c-make-mode-syntax-table dakota))))

(defvar dakota-mode-abbrev-table nil
  "Abbreviation table used in dakota-mode buffers.")
(c-define-abbrev-table 'dakota-mode-abbrev-table
  ;; Keywords that if they occur first on a line might alter the
  ;; syntactic context, and which therefore should trig reindentation
  ;; when they are completed.
  '(("else" "else" c-electric-continued-statement 0)
    ("while" "while" c-electric-continued-statement 0)
    ("catch" "catch" c-electric-continued-statement 0)
    ("finally" "finally" c-electric-continued-statement 0)))

(defvar dakota-mode-map (let ((map (c-make-inherited-keymap)))
		      ;; Add bindings which are only useful for Dakota
		      map)
  "Keymap used in dakota-mode buffers.")

(easy-menu-define dakota-menu dakota-mode-map "Dakota Mode Commands"
		  ;; Can use `dakota' as the language for `c-mode-menu'
		  ;; since its definition covers any language.  In
		  ;; this case the language is used to adapt to the
		  ;; nonexistence of a cpp pass and thus removing some
		  ;; irrelevant menu alternatives.
		  (cons "Dakota" (c-lang-const c-mode-menu dakota)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.dk$" . dakota-mode))

;;;###autoload
(defun dakota-mode ()
  "Major mode for editing Dakota.

The hook `c-mode-common-hook' is run with no args at mode
initialization, then `dakota-mode-hook'.

Key bindings:
\\{dakota-mode-map}"
  (interactive)
  (kill-all-local-variables)
  (c-initialize-cc-mode t)
  (set-syntax-table dakota-mode-syntax-table)
  (setq major-mode 'dakota-mode
        mode-name "Dakota"
        local-abbrev-table dakota-mode-abbrev-table
        abbrev-mode t)
  (use-local-map c-mode-map)
  ;; `c-init-language-vars' is a macro that is expanded at compile
  ;; time to a large `setq' with all the language variables and their
  ;; customized values for our language.
  (c-init-language-vars dakota-mode)
  ;; `c-common-init' initializes most of the components of a CC Mode
  ;; buffer, including setup of the mode menu, font-lock, etc.
  ;; There's also a lower level routine `c-basic-common-init' that
  ;; only makes the necessary initialization to get the syntactic
  ;; analysis and similar things working.
  (c-common-init 'dakota-mode)
  (easy-menu-add dakota-menu)
  (run-hooks 'c-mode-common-hook)
  (run-hooks 'dakota-mode-hook)
  (c-update-modeline))


(provide 'dakota-mode)
