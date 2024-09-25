;; -*- lexical-binding: t; -*-

(setq this-config-org-file "~/emacs-config/config.org")

(defun rostre/org-babel-tangle-config ()
  (when (string-equal (buffer-file-name)
                      (expand-file-name this-config-org-file))
    (let ((org-confirm-babel-evaluate nil))
      (org-babel-tangle))))

(add-hook 'org-mode-hook
          (lambda ()
            (add-hook 'after-save-hook #'rostre/org-babel-tangle-config)))

(defvar elpaca-installer-version 0.7)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                 ,@(when-let ((depth (plist-get order :depth)))
                                                     (list (format "--depth=%d" depth) "--no-single-branch"))
                                                 ,(plist-get order :repo) ,repo))))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

(elpaca elpaca-use-package
  (elpaca-use-package-mode))

(setq use-package-always-ensure t)

(when (eq system-type 'darwin)
  (progn
    (setq mac-option-key-is-meta nil)
    (setq mac-option-modifier 'super)
    (setq mac-command-key-is-meta t)
    (setq mac-command-modifier 'meta)))

(use-package general
  :ensure (:wait t) ;; wait as we use general.el throughout the rest of the config
  :config (general-define-key "M-o" 'other-window))

(repeat-mode)

(use-package which-key
  :diminish which-key-mode
  :config
  (setq which-key-idle-delay 0.3)
  (which-key-mode))

(if (eq system-type 'darwin)
    (setq rostre/font-size 140)
  (setq rostre/font-size 120))

(set-face-attribute 'default nil
                    :font "Iosevka"
                    :height rostre/font-size)

(set-face-attribute 'fixed-pitch nil
                    :font "Iosevka"
                    :height rostre/font-size)

(set-face-attribute 'variable-pitch nil
                    :font "Iosevka"
                    :height rostre/font-size)

(defun rostre/org-faces ()
  (set-face-attribute 'org-document-title nil :height 1.4)
  (set-face-attribute 'org-todo nil :height 1.0)
  (set-face-attribute 'org-level-1 nil :height 1.3)
  (set-face-attribute 'org-level-2 nil :height 1.2)
  (set-face-attribute 'org-level-3 nil :height 1.2)
  (set-face-attribute 'org-level-4 nil :height 1.2)
  (set-face-attribute 'org-level-5 nil :height 1.2)
  (set-face-attribute 'org-level-6 nil :height 1.2))

(add-hook 'org-mode-hook 'rostre/org-faces)

;; Remove title bar on Mac
(when (eq system-type 'darwin)
  (add-to-list 'default-frame-alist '(undecorated-round . t)))

;; Remove UI cruft
(tool-bar-mode -1)
(menu-bar-mode -1)
(toggle-scroll-bar -1)

(add-hook 'prog-mode-hook 'display-line-numbers-mode)

(use-package breadcrumb
  :config
  (breadcrumb-mode))

(use-package org-bars
  :if (eq system-type 'gnu/linux) ;; it's not rendering properly on mac
  :ensure (:host github :repo "https://github.com/tonyaldon/org-bars")
  :hook (org-mode . org-bars-mode))

(use-package timu-rouge-theme
  :config (load-theme 'timu-rouge t))

(define-minor-mode global-transparent-background-mode
  "Toggles background transparency for emacs frames"
  :init-value nil
  :global t
  (if global-transparent-background-mode
      (progn
        (set-frame-parameter (selected-frame) 'alpha '(95 . 95))
        (add-to-list 'default-frame-alist '(alpha . (95 95))))
    (progn
      (set-frame-parameter (selected-frame) 'alpha '(100 . 100))
      (assq-delete-all 'alpha default-frame-alist))))

(general-define-key "C-c x" 'global-transparent-background-mode)

(when (eq system-type 'gnu/linux)
  (global-transparent-background-mode))

(use-package all-the-icons
  :init
  (setq all-the-icons-was-installed (not (elpaca-installed-p 'all-the-icons)))
  :config
  (when all-the-icons-was-installed
    (all-the-icons-install-fonts)))

(use-package keycast
  :config (keycast-mode-line-mode))

(use-package helpful
  :bind
  ([remap describe-function] . describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . describe-variable)
  ([remap describe-key] . helpful-key))

(use-package vertico
  :config
  (setq vertico-cycle t)
  (vertico-mode))

(use-package consult
  :config
  (general-define-key "s-s" 'consult-line
                      "C-x b" 'consult-buffer
                      "C-c g" 'consult-ripgrep
                      "C-c o" 'consult-outline))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic))
  (setq completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :after vertico
  :config
  (setq marginalia-annotators '(marginalia-annotators-heavy marginalia-annotators-light nil))
  (marginalia-mode))

(use-package corfu
  :bind
  ;; use super-Space to use orderless search in corfu completions
  (:map corfu-map ("s-SPC" . corfu-insert-separator))
  :config
  (corfu-cycle t) ;; cycle selection box
  (corfu-auto t) ;; automatically try to complete
  (corfu-preview-current t)
  (global-corfu-mode)
  (corfu-popupinfo-mode))

(use-package cape)

(use-package embark
  :config
  (general-define-key "C-." 'embark-act)

  (defvar-keymap embark-org-agenda-heading-map
    :doc "Keymap for org-agenda view actions"
    :parent embark-general-map
    "t" #'org-agenda-todo
    "i" #'org-agenda-clock-in))

(use-package embark-consult)

(defun avy-action-embark (pt)
  (unwind-protect
      (save-excursion
        (goto-char pt)
        (embark-act))
    (select-window
     (cdr (ring-ref avy-ring 0))))
  t)

(defun avy-action-mark-to-char (pt)
  (activate-mark)
  (goto-char pt))

(defun avy-action-helpful (pt)
  (save-excursion
    (goto-char pt)
    (helpful-at-point))
  (select-window
   (cdr (ring-ref avy-ring 0)))
  t)

(use-package avy
  :config
  (general-define-key "C-;" 'avy-goto-char-timer)
  (setf (alist-get ?. avy-dispatch-alist) 'avy-action-embark
	(alist-get ?k avy-dispatch-alist) 'avy-action-kill-stay
	(alist-get ?w avy-dispatch-alist) 'avy-action-copy
	(alist-get ?y avy-dispatch-alist) 'avy-action-yank
	(alist-get ?M avy-dispatch-alist) 'avy-action-mark-to-char
	(alist-get ?H avy-dispatch-alist) 'avy-action-helpful))

(defun rostre/split-window-right ()
  (interactive)
  (select-window (split-window-right)))

(general-define-key "C-x 3" 'rostre/split-window-right)

(defun rostre/split-window-below ()
  (interactive)
  (select-window (split-window-below)))

(general-define-key "C-x 2" 'rostre/split-window-below)

(defun rostre/delete-whitespace-backwards ()
  "Delete all of the whitespace before point"
  (interactive)
  (save-excursion
    (setq-local end-loc (point))
    (re-search-backward "[^\s\n\t]")
    (forward-char)
    (delete-region (point) end-loc)))

(general-define-key "s-<backspace>" 'rostre/delete-whitespace-backwards)

(defun rostre/delete-whitespace-forwards ()
  "Delete all of the whitespace before point"
  (interactive)
  (save-excursion
    (setq-local start-loc (point))
    (re-search-forward "[^\s\n\t]")
    (forward-char)
    (delete-region start-loc (point))))

(general-define-key "s-d" 'rostre/delete-whitespace-forwards)

(defalias 'yes-or-no-p 'y-or-n-p)

(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)

(setq history-length 25)
(savehist-mode 1)

;; create the directory if it doesn't exist
(when (not (file-directory-p "~/.emacs-temp-files"))
  (make-directory "~/.emacs-temp-files/"))
(setq temporary-file-directory "~/.emacs-temp-files/")

;; redirect backup files
(setq backup-directory-alist
      `((".*" . ,temporary-file-directory)))

;; redirect autosave files
(setq auto-save-file-name-transforms
      `((".*" ,temporary-file-directory t)))

;; redirect lock files
(setq lock-file-name-transforms
      `((".*" ,temporary-file-directory t)))

(general-define-key :prefix "C-c"
                    "c" (lambda () (interactive) (find-file "~/emacs-config/config.org"))
                    "r" (lambda () (interactive) (load-file "~/emacs-config/init.el"))
                    "w" 'window-swap-states)

(use-package seq)
(use-package transient
  :after 'seq)

(use-package magit
  :after transient seq
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(setq work-notes-directory "~/work_notes/")
(setq personal-notes-directory "~/synced_notes/")

(defun rostre/org-buffer-setup ()
  (variable-pitch-mode 1)
  (visual-line-mode 1)
  (org-indent-mode))

(add-hook 'org-mode-hook 'rostre/org-buffer-setup)

(setq org-ellipsis " ⮠")
(setq org-cycle-separator-lines -1)
(setq org-image-actual-width nil)
(setq org-hide-emphasis-markers t)

(setq org-log-done 'time)

(setq org-log-into-drawer t)

(setq org-todo-keywords
      '((sequence "TODO(t)" "RVEW(n!)" "WAIT(w@/!)" "|" "DONE(d!)" "CANC(c@)")))

(setq org-priority-highest ?A)
(setq org-priority-lowest ?E)

(setq org-tag-alist '())

(use-package org-download
  :config
  (general-define-key "C-c y" 'org-download-clipboard))

(general-define-key "C-c q" 'org-store-link)

(defun rostre/set-creation-date-property-on-new-heading ()
  (save-excursion
    (org-back-to-heading)
    (org-set-property "CREATED" (format-time-string "[%Y-%m-%d %T]"))))

(add-hook 'org-insert-heading-hook #'rostre/set-creation-date-property-on-new-heading)

(setq org-capture-templates
  '(("t" "Work Task" entry (file+headline "~/work_notes/work_journal.org" "work journal")
     "\n* TODO [#%^{Priority: |A|B|C|D|E}] %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n" :empty-lines-before 1)
    ("n" "Work Note" entry (file+headline "~/work_notes/work_journal.org" "work journal")
     "\n* %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n" :empty-lines-before 1 :clock-in t)
    ("d" "Work Diary" entry (file+headline "~/work_notes/work_diary.org" "work diary")
     "\n* %?\n%^T" :empty-lines-before 1)
    ("T" "Personal Task" entry (file+headline "~/synced_notes/journal.org" "personal journal")
     "\n* TODO [#%^{Priority: |A|B|C|D|E}] %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n" :empty-lines-before 1)
    ("N" "Personal Note" entry (file+headline "~/synced_notes/journal.org" "personal journal")
     "\n* %?\n:PROPERTIES:\n:CREATED: %U\n:END:\n\n" :empty-lines-before 1)))

(general-define-key "C-c f c" 'org-capture)

(use-package denote
  :ensure (:wait t) ;; wait so that denote functions can be referenced later
  :config
  ;; Key bindings
  (general-define-key :prefix "C-c d"
                      "n" 'denote
                      "c" 'rostre/capture-to-denote
                      "l" 'denote-link
                      "o" 'denote-link-after-creating
                      "f" 'consult-notes))

(setq denote-templates
  `(
    (normal . "")
    ;; A metanote is a collection of links to other notes
    (metanote . ,(concat "* links"
             "\n\n"))
    ;; A project is a collection of TODO tasks.
    (project . ,(concat "* tasks\n\n"
                        "* diary\n\n"
                        "* notes\n\n"
                        "* reminders\n\n"))))

(setq denote-prompts
      '(title keywords template))

(setq denote-org-store-link-to-heading t)

(setq denote-org-front-matter
    "#+title:      %1$s
#+category:   %1$s
#+date:       %2$s
#+filetags:   %3$s
#+identifier: %4$s
\n")

(use-package denote-menu
  :custom
  (denote-menu-title-column-width 50)
  (denote-menu-show-file-type nil)
  :bind (:map denote-menu-mode-map
      ("/ r" . denote-menu-filter)
      ("/ k" . denote-menu-filter-by-keyword)
      ("/ o" . denote-menu-filter-out-keyword)
      ("d" . denote-menu-export-to-dired)
      ("c" . denote-menu-clear-filters)
      ("g" . denote-menu-list-notes)))

(use-package consult-notes
  :config
  (consult-notes-denote-mode))

(general-define-key "C-c a" 'org-agenda)

(setq org-agenda-file-regexp "\\`[^.].*\\.org\\'")

(setq org-agenda-window-setup 'current-window)

(setq org-agenda-skip-scheduled-if-done t)
(setq org-agenda-skip-deadline-if-done t)

(setq org-agenda-include-diary t)

(setq org-agenda-mouse-1-follows-link nil)

(setq org-agenda-clockreport-parameter-plist '(:link t :maxlevel 2 :fileskip0 t :filetitle t))

(defun rostre/org-notes-files (dir)
  (if (file-directory-p dir)
      (directory-files dir t "\.org$")
    '()))

(setq org-agenda-files (append
                        (rostre/org-notes-files work-notes-directory)
                        (rostre/org-notes-files personal-notes-directory)))

(setq org-agenda-custom-commands 
    '(("j" "Dashboard"
       ((agenda "" (
                    (org-deadline-warning-days 14)
                    (org-agenda-span 'day)
                    (org-agenda-start-with-log-mode '(state clock))
                    (org-agenda-prefix-format "%-10t %-12s %-6e")))
        (tags-todo "-create_jira_card+PRIORITY=\"A\"-SCHEDULED>\"<2000-01-01 Sat>\""
                   ((org-agenda-overriding-header "Do Now")
                    (org-agenda-sorting-strategy '(effort-up))
                    (org-agenda-prefix-format "%-6e %-30c")
                    (org-agenda-files
                     (rostre/org-notes-files work-notes-directory))))
        (tags-todo "-create_jira_card+PRIORITY=\"B\"-SCHEDULED>\"<2000-01-01 Sat>\""
                   ((org-agenda-overriding-header "Do Later")
                    (org-agenda-sorting-strategy '(effort-up))
                    (org-agenda-prefix-format "%-6e %-30c")
                    (org-agenda-files
                     (rostre/org-notes-files work-notes-directory))))
        (tags-todo "create_jira_card-SCHEDULED>\"<2000-01-01 Sat>\""
                   ((org-agenda-overriding-header "Create Jira Cards")
                    (org-agenda-prefix-format "%-6e %-30c")
                    (org-agenda-files
                     (rostre/org-notes-files work-notes-directory))))
        (tags-todo "-SCHEDULED>\"<2000-01-01 Sat>\""
                   ((org-agenda-overriding-header "Personal")
                    (org-agenda-sorting-strategy '(effort-up))
                    (org-agenda-prefix-format "%-6e %-30c")
                    (org-agenda-files
                     (list (file-name-concat personal-notes-directory "journal.org")))))))
        ("r" "Reminders"
         ((tags-todo "reminder"
                     ((org-agenda-prefix-format "%-6e %-30c")))))
        ("d" "Deadlines"
         ((agenda "Deadlines"
                  ((org-agenda-overriding-header "Deadlines")
                   (org-agenda-span 'month)
                   (org-agenda-time-grid nil)
                   (org-agenda-entry-types '(:deadline))
                   (org-agenda-show-all-dates nil)
                   (org-deadline-warning-days 0)))))))

(use-package ob-http
  :ensure (:wait t))

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (python . t)
   (shell . t)
   (http . t)
   (sql . t)))

(setq org-babel-python-command "/usr/local/bin/python3.9")

(setq org-confirm-babel-evaluate nil)

(require 'org-tempo)
(add-to-list 'org-structure-template-alist '("sh" . "src shell"))
(add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
(add-to-list 'org-structure-template-alist '("py" . "src python"))
(add-to-list 'org-structure-template-alist '("http" . "src http :pretty"))
(add-to-list 'org-structure-template-alist '("sql" . "src sql"))
(add-to-list 'org-structure-template-alist '("lua" . "src lua"))

(require 'ox-md nil t)

(setq-default tab-width 4)

(use-package indent-bars
  :config
  (require 'indent-bars-ts)
  (setq indent-bars-treesit-support t)
  :hook
  (prog-mode . indent-bars-mode))

(setq indent-bars-treesit-scope '((rust block)))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package yasnippet
  :config
  (yas-global-mode 1)
  (setq yas-indent-line 'fixed))

(use-package yasnippet-snippets
  :after yasnippet)

(setq treesit-language-source-alist
 '((bash "https://github.com/tree-sitter/tree-sitter-bash" "v0.20.5")
   (c "https://github.com/tree-sitter/tree-sitter-c" "v0.20.7")
   (cpp "https://github.com/tree-sitter/tree-sitter-cpp" "v0.23.0")
   (cmake "https://github.com/uyha/tree-sitter-cmake" "v0.5.0")
   (css "https://github.com/tree-sitter/tree-sitter-css" "v0.23.0")
   (elisp "https://github.com/Wilfred/tree-sitter-elisp" "1.5.0")
   (go "https://github.com/tree-sitter/tree-sitter-go" "v0.23.1")
   (gomod "https://github.com/camdencheek/tree-sitter-go-mod" "v1.1.0")
   (html "https://github.com/tree-sitter/tree-sitter-html" "v0.23.0")
   (javascript "https://github.com/tree-sitter/tree-sitter-javascript" "v0.23.0" "src")
   (json "https://github.com/tree-sitter/tree-sitter-json" "v0.23.0")
   (make "https://github.com/alemuller/tree-sitter-make")
   (markdown "https://github.com/ikatyang/tree-sitter-markdown" "v0.7.1")
   (python "https://github.com/tree-sitter/tree-sitter-python" "v0.23.2")
   (rust "https://github.com/tree-sitter/tree-sitter-rust" "v0.23.0")
   (toml "https://github.com/tree-sitter/tree-sitter-toml" "v0.5.1")
   (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.0" "tsx/src")
   (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "v0.23.0" "typescript/src")
   (yaml "https://github.com/ikatyang/tree-sitter-yaml" "v0.5.0")))

(setq major-mode-remap-alist
 '((yaml-mode . yaml-ts-mode)
   (bash-mode . bash-ts-mode)
   (js2-mode . js-ts-mode)
   (typescript-mode . typescript-ts-mode)
   (json-mode . json-ts-mode)
   (css-mode . css-ts-mode)
   (python-mode . python-ts-mode)
   (go-mode . go-ts-mode)
   (rust-mode . rust-ts-mode)))

(use-package eldoc) ;; dependency

(use-package eglot
  :after eldoc
  :config
  (add-hook 'python-ts-mode-hook 'eglot-ensure)
  (add-hook 'go-ts-mode-hook 'eglot-ensure)
  (add-hook 'rust-ts-mode-hook 'eglot-ensure)
  (setq eglot-ignored-server-capabilities '())
  (setq eldoc-echo-area-prefer-doc-buffer t)
  :bind
  (:map eglot-mode-map
        ("C-c l f" . eglot-format-buffer)
        ("C-c l e" . flymake-show-project-diagnostics)
        ("C-c l n" . flymake-goto-next-error)
        ("C-c l p" . flymake-goto-prev-error)
        ("C-c l a" . eglot-code-actions)
        ("C-c l r" . eglot-rename)
        ("C-c l d" . xref-find-definitions)
        ("C-c l x" . xref-find-references)
        ("C-c l m" . compile)))

(use-package jsonrpc) ;; dependency

(use-package dape
  :after jsonrpc)

(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump))
  (:map dired-mode-map
        ;; b goes up to parent dir
        ("b" . 'dired-up-directory)
        ;; N creates new file
        ("N" . 'find-file))
  :config
  (require 'dired-x)
  :custom
  ;; Use gls for driving dired on mac
  ((when system-type 'darwin
         (insert-directory-program "gls"))
   (dired-use-ls-dired t)
   ;; Put all the directories at the top, hide backup files
   (dired-listing-switches "-aghoB --group-directories-first")
   (delete-by-moving-to-trash t)))

(use-package vterm
  :commands vterm
  :config
  (setq term-prompt-regexp "^[^#$%>\n]*[#$%>] *")
  (setq vterm-max-scrollback 10000)
  ;; key bindings
  (general-define-key "C-c v" 'multi-vterm))

(use-package multi-vterm)

(defalias 'rostre/macro/record-feedback
  (kmacro "C-c d c C-k t e a m - l o g b o o k <return> n"))
(general-define-key "C-c k n" 'rostre/macro/record-feedback)

(defalias 'rostre/macro/new-todo
  (kmacro "C-c d c <return> t <return>"))
(general-define-key "C-c k t" 'rostre/macro/new-todo)

(defalias 'rostre/macro/indent-block
  (kmacro "C-x r t SPC SPC SPC SPC <return>"))
(general-define-key "C-c k i" 'rostre/macro/indent-block)

(defalias 'rostre/macro/paste-image
 (kmacro "C-c y C-p C-p C-e <return> i m g w i d t h <tab> C-c C-x C-v C-c C-x C-v"))
(general-define-key "C-c k y" 'rostre/macro/paste-image)

(setq in-office nil)

;;  (use-package copilot
;;    :if in-office
;;    :vc (:fetcher github :repo copilot-emacs/copilot.el)
;;    :hook (prog-mode . copilot-mode)
;;    :bind (:map copilot-completion-map
;;                ("<tab>" . 'copilot-accept-completion)
;;                ("TAB" . 'copilot-accept-completion)
;;                ("C-TAB" . 'copilot-accept-completion-by-word)
;;                ("C-<tab>" . 'copilot-accept-completion-by-word)))

(defun rostre/filter-for-one-to-one-meeting ()
  (interactive)
  (let ((person-tag
         (completing-read "1-1 for person: " (org-get-buffer-tags)))
        (week-ago
         (format-time-string "%Y-%m-%d"
                             (days-to-time
                              (-
                               (- (time-to-days (current-time)) 7)
                               (time-to-days 0))))))
    (org-match-sparse-tree
     nil
     (concat "+" person-tag "+CREATED>=\"<" week-ago ">\"|+downflow+CREATED>=\"<" week-ago ">\""))))

(general-define-key "C-c f o" 'rostre/filter-for-one-to-one-meeting)

(use-package elfeed
:config
(setq elfeed-feeds '(
      ("https://news.ycombinator.com/rss" code)
      ("https://rostre.bearblog.dev/feed/?type=rss" code)
      ("https://planet.emacslife.com/atom.xml" emacs code))))

(use-package mastodon
  :custom
  (mastodon-instance-url "https://hachyderm.io")
  (mastodon-active-user "robsws"))

(setq erc-server "irc.libera.chat"
    erc-nick "rostre"
    erc-track-shorten-start 8
    erc-autojoin-channels-alist '(("irc.libera.chat" "#systemcrafters" "#emacs"))
    erc-kill-buffer-on-part t
    erc-auto-query 'bury)

(use-package speed-type)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-files '("/home/robstreeting/work_notes/journal.org")))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
