;; Normally, killing the newline between indented lines doesn’t remove
;; any extra spaces caused by indentation. That is, placing the cursor
;; (symbolized by []) at
;;         AAAAAAAAAA[]
;;         AAAAAAAAAA
;; and pressing C-k (bound to kill-line) results in
;;         AAAAAAAAAA[]        AAAAAAAAAA
;; when it might be more desirable to have

;;         AAAAAAAAAA[]AAAAAAAAAA
;; http://www.emacswiki.org/emacs/AutoIndentation
(defun kill-and-join-forward (&optional arg)
  "If at end of line, join with following; otherwise kill line.
    Deletes whitespace at join."
  (interactive "P")
  (if (and (eolp) (not (bolp)))
      (delete-indentation t)
    (kill-line arg)))
(global-set-key "\C-k" 'kill-and-join-forward)

;; -----------------------
;; * Balance plein écran *
(when window-system
  (defun toggle-full-screen ()
    "Toggle between full screen and partial screen display on X11;
    courtesy of http://www.emacswiki.org/cgi-bin/wiki/FullScreen"
    (interactive)
    (x-send-client-message nil 0 nil "_NET_WM_STATE" 32
                           '(2 "_NET_WM_STATE_FULLSCREEN" 0)))
  (global-set-key (kbd "C-z") 'toggle-full-screen))

;; ---------------------------------------------
;; * Obtenir le nom complet du fichier courant *
(defun pi-buffer-file-name (prefix &optional killit)
  "Show the `buffer-file-name' (if any) and make it
the latest kill in the kill ring if `killit' is t.
With prefix, write in the current buffer."
  (interactive "P")
  (if buffer-file-name
      (if prefix
          (insert buffer-file-name)
        (if killit
            (kill-new (message buffer-file-name))
          (message buffer-file-name)))
    (message "No file-name attached to the bufer")))
;; F8     : echo filename in the minibuffer
;; C-u F8 : insert filename in the current buffer
(global-set-key (kbd "<f8>") 'pi-buffer-file-name)
;; S-f8   : echo filename in the minibuffer and put in the kill ring.
(global-set-key (kbd "<S-f8>")
                (lambda nil
                  (interactive)
                  (pi-buffer-file-name nil t)))

;; ------------------------------
;; * Suppression rapide de mots *
(defun backward-delete-word (arg)
  "Delete characters backward until encountering the beginning of a word.
With argument ARG, do this that many times."
  (interactive "p")
  (delete-region (point) (progn (backward-word arg) (point))))
(global-set-key (kbd "<C-backspace>") 'backward-delete-word)

(defun delete-sexp (&optional arg)
  "Delete the sexp (balanced expression) following point.
With ARG, delete that many sexps after point.
Negative arg -N means delete N sexps before point.
This command assumes point is not in a string or comment."
  (interactive "p")
  (let ((opoint (point)))
    (forward-sexp (or arg 1))
    (delete-region opoint (point))))

(defun backward-delete-sexp (&optional arg)
  "Delete the sexp (balanced expression) preceding point.
With ARG, delete that many sexps before point.
Negative arg -N means delete N sexps after point.
This command assumes point is not in a string or comment."
  (interactive "p")
  (delete-sexp (- (or arg 1))))

(global-set-key (kbd "<M-backspace>") 'backward-delete-sexp)
(global-set-key (kbd "<M-delete>")
                (lambda ()
                  (interactive)
                  (beginning-of-line)
                  (kill-line)))

(global-set-key (kbd "<C-delete>")
                (lambda (&optional arg)
                  (interactive)
                  (kill-word arg)))

;; ------------------------
;; * Key for other-window *
(global-set-key (kbd "<C-next>")
                (lambda ()
                  (interactive)
                  (other-window 1 nil)))
(global-set-key (kbd "<C-prior>")
                (lambda ()
                  (interactive)
                  (other-window -1 nil)))

;; -------------------------------------------
;; * Filename completion anywhere with S-Tab *
(autoload 'comint-dynamic-complete-filename "comint" "" t)
;; Liste des suffixes à négliger pendant le complètement:
(setq comint-completion-fignore (quote ("{" "}" "(" ")" "$" "=" "\"" "`" "'" "[" "]" "%" "<" ">")))
(global-set-key (kbd "<S-tab>") 'comint-dynamic-complete-filename)
(global-set-key (kbd "<S-iso-lefttab>") 'comint-dynamic-complete-filename)

;; ----------------------
;; * Keys for info-mode *
(add-hook 'Info-mode
          (lambda ()
            (define-key Info-mode-map (kbd "<") 'Info-history-back)
            (define-key Info-mode-map (kbd ">") 'Info-history-forward)))

;; ---------------------------------------
;; * Visiter l'url ou se trouve le point *
(global-set-key (kbd "C-c b") 'browse-url-at-point)

;; ----------------------------------------------
;; * Supprime le buffer et la fenêtre courrante *
(defun pi-kill-window-and-buffer()
  "* Delete current window and buffer."
  (interactive)
  (kill-buffer (current-buffer))
  (if (not (one-window-p nil))(delete-window)))
(global-set-key [f12] 'pi-kill-window-and-buffer)


;; -----------------------
;; * Bascule de la fonte *
(defun pi-toggle-font()
  "Toggle between large and small font."
  (interactive)
  (if (string= pi-current-font-size "small")
      (progn
        (set-frame-font pi-default-font t)
        (setq pi-current-font-size "big"))
    (progn
      (set-frame-font pi-small-font t)
      (setq pi-current-font-size "small"))))
;; (global-set-key (kbd "C-f") `pi-toggle-font)


;; --------------------------
;; * Indente tout le buffer *
(defun pi-indent-whole-html-buffer nil
  (interactive)
  (save-excursion
    (beginning-of-buffer)
    (let ((ppoint (point)))
      (while (search-forward-regexp "<pre.*?>"  (point-max) t)
        (indent-region ppoint (point) nil)
        (search-forward-regexp "</pre>" (point-max) t)
        (setq ppoint (+ 1 (point))))
      (indent-region ppoint (point-max) nil))))

;; ---------------------------
;; * Indent the whole buffer *
(defun pi-indent-whole-buffer nil
  "Indent the whole buffer. If the mark `(concat comment-start \"--indent after--\")`
is found in the buffer the indentation start after the last mark found."
  (interactive)
  (save-excursion
    (if (assoc-ignore-case major-mode (list "xhtml-mode" "html-mode" "nxhtml-mode"))
        (pi-indent-whole-html-buffer)
      (progn
        (beginning-of-buffer)
        (let ((ppoint (point)))
          (while (search-forward-regexp
                  (concat
                   (regexp-quote comment-start)
                   "*--noindent--") (point-max) t)
            (previous-line)
            (indent-region ppoint (point) nil)
            (next-line 2)
            (setq ppoint (point)))
          (indent-region ppoint (point-max) nil))))))
(global-set-key (kbd "<C-S-iso-lefttab>") 'pi-indent-whole-buffer)

;; --------------------------------
;; * Déplacer un ligne facilement *
(defun move-line-up (&optional n)
  "Moves current line up leaving point in place.  With a prefix
argument, moves up N lines."
  (interactive "p")
  (if (null n) (setq n 1))
  (let ((col (current-column)))
    (beginning-of-line)
    (next-line 1)
    (transpose-lines (- n))
    (previous-line 1)
    (forward-char col)))
(global-set-key [(meta up)] 'move-line-up)

(defun move-line-down (&optional n)
  "Moves current line down leaving point in place.  With a prefix
argument, moves down N lines."
  (interactive "p")
  (if (null n) (setq n 1))
  (let ((col (current-column)))
    (beginning-of-line)
    (next-line 1)
    (transpose-lines  n)
    (previous-line 1)
    (forward-char col)))
(global-set-key [(meta down)] 'move-line-down)

;; ---------------------
;; * Find file as root *
(defun find-file-root ()
  "* Find file as root."
  (interactive)
  (let ((file (ido-read-file-name "Find file AS ROOT: ")))
    (find-file (concat "/su::" file))))
(global-set-key [(control x) (control r)] 'find-file-root)

;; ----------------------------
;; * Retour en début de ligne *
(defun pi-home()
  "* Move cursor at beginning of line or first non blank character
depending where the cursor is."
  (interactive)
  (let ((pt_indent (point)))
    (back-to-indentation)
    (if (eq pt_indent (point))
        (beginning-of-line-nomark))
    ))
(global-set-key [(home)] 'pi-home)
(global-set-key (kbd "C-a") 'pi-home)


(defun pi-fill ()
  "Use fill line or region as auto-fill-mode does"
  (interactive)
  (save-excursion
    (if mark-active
        (fill-region-as-paragraph (point) (mark))
      (do-auto-fill))))
(global-set-key (kbd "M-q") 'pi-fill)

;; See also comment-dwim
(defun pi-?comment (&optional indentp)
  (interactive)
  (save-excursion
    (if mark-active
        (let ((br (if (< (point) (mark)) (point) (mark)))
              (be (if (> (point) (mark)) (point) (mark))))
          (comment-or-uncomment-region br be)
          (and indentp (indent-region br be)))
      (let ((br (progn  (back-to-indentation) (point)))
            (be (progn (end-of-line) (point))))
        (comment-or-uncomment-region br be)
        (and indentp (indent-according-to-mode))))))
(global-set-key (kbd "C-%")
                (lambda nil
                  (interactive)
                  (pi-?comment t)))
(global-set-key (kbd "C-;") 'pi-?comment)


;; -------------------------
;; * Entête de commentaire *
(defface pi-comment-section-face
  `((t
     ( :foreground "yellow")))
  "Face used to highlighting header of comment section."
  :group 'pi-comment)
(defface pi-comment-sub-section-face
  `((t
     ( :foreground "white")))
  "Face used to highlighting header of comment section."
  :group 'pi-comment)

(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (font-lock-add-keywords
             'nil
             '(("\\(;; \\*=*\\*$\\)" 1 'pi-comment-section-face t)
               ("\\(;; \\*\\..*\\.\\*$\\)" 1 'pi-comment-section-face t)
               ("\\(;; -*\n;; \\*.*\\*$\\)" 1 'pi-comment-sub-section-face t)))))
(font-lock-add-keywords
 'emacs-lisp-mode-hook
 '(("\\(;; -*\n;; \\*.*\\*$\\)" 1 'pi-comment-sub-section-face t)))

(defun pi-insert-comment-section ()
  "* To insert a section comments."
  (interactive)
  (let* ((str (if (and mark-active transient-mark-mode)
                  (prog1
                      (buffer-substring (region-beginning) (region-end))
                    (delete-region (region-beginning) (region-end)))
                (read-string "Section comment: ")))
         (str_ (if (string= str "") " - " str))
         (v1 (make-string (- fill-column 15) ?=))
         (v2 (- fill-column 15 (length str_)))
         (spce (make-string (floor v2 2) ?.))
         (pt (progn (beginning-of-line) (point))))
    (insert (concat "*" v1 "*\n*" spce str_ spce
                    (unless (= (ceiling v2 2) (/ v2 2)) ".")
                    "*\n*" v1 "*"))
    (comment-region pt (point))
    (next-line)
    (beginning-of-line)))
(global-set-key (kbd "C-µ") 'pi-insert-comment-section)

(defun pi-insert-comment-sub-section ()
  "* To insert a section sub comments"
  (interactive)
  (let* ((str (if (and mark-active transient-mark-mode)
                  (prog1
                      (buffer-substring (region-beginning) (region-end))
                    (delete-region (region-beginning) (region-end)))
                (read-string "Sub section comment: ")))
         (str_ (if (string= str "") " - " str))
         (v1 (make-string (+ (length str_) 4) ?-))
         (pt (progn (beginning-of-line) (point))))
    (insert (concat  v1 "\n* " str_ " *"))
    (comment-region pt (point))
    (next-line)
    (beginning-of-line)))
(global-set-key (kbd "C-*") 'pi-insert-comment-sub-section)


;; --------------------------------------------------------
;; * Seeking a makefile recursively in directories higher *
(defun pi-get-above-makefile ()
  "* From http://www.emacswiki.org/cgi-bin/wiki/UsingMakefileFromParentDirectory."
  (expand-file-name
   (loop as d = default-directory then
         (expand-file-name
          ".." d) if (or
                      (file-exists-p (expand-file-name "makefile" d))
                      (file-exists-p (expand-file-name "Makefile" d)))
          return d)))
(defun pi-compile-above-makefile ()
  (interactive)
  (let* ((mkf (pi-get-above-makefile))
         (default-directory (directory-file-name mkf)))
    (cd default-directory)
    (compile "make")))
(global-set-key (kbd "<f9>") 'pi-compile-above-makefile)

;; -----------------------------------------------
;; * Scroll down the page rather than the cursor *
;; use the key "Scroll Lock Num" ("Num Défil" in french) to toggle.
;; C-up et C-down
(autoload 'pi-scroll-lock-mode "pi-scroll-lock" "Toggle pi-scroll-lock-mode." t)
(global-set-key (kbd "<Scroll_Lock>") 'pi-scroll-lock-mode)
;; Switches to hl-line-mode when the cursor is locked.
(setq pi-scroll-hl t)


;; In certain mode $, {, (, [ executing `skeleton-pair-insert-maybe'
;; Preceded by Control, this feature is ignored.
(global-set-key (kbd "C-$")
                '(lambda ()
                   (interactive)
                   (insert "$")))

(global-set-key (kbd "C-\"")
                (lambda ()
                  (interactive)
                  (insert "\"")))

(global-set-key (kbd "C-{")
                (lambda ()
                  (interactive)
                  (insert "{")))

(global-set-key (kbd "C-(")
                (lambda ()
                  (interactive)
                  (insert "(")))

;; C-/ is undo by default
(global-set-key (kbd "C-:") 'redo)

;; Non-breaking spaces with quotes please.
(global-set-key (kbd "«") (lambda nil (interactive) (insert "« ")))
(global-set-key (kbd "»") (lambda nil (interactive) (insert " »")))
(global-set-key (kbd "C-'") '(lambda nil (interactive (insert "’"))))

;; --------------------------------
;; * Highlight the current column *
(when (locate-library "column-marker")
  (autoload 'column-marker-1 "column-marker" "Highlight a column." t)
  ;; http://www.emacswiki.org/cgi-bin/wiki/col-highlight.el
  (require 'col-highlight)
  ;; Raccourci sur [f10]
  (global-set-key (kbd "<f10>") 'column-highlight-mode))

;; -----------------------------------
;; * Return to the previous position *
(require 'jumptoprevpos)
(global-set-key (kbd "C-<") 'jump-to-prev-pos)
(global-set-key (kbd "C->") 'jump-to-next-pos)

;; Define C-x up | C-x down | C-x right | C-x left to resize the windows
(require 'pi-resize-window "pi-resize-window.el" t)

;; Default is dabbrev-expand mais hippie-expand est plus généraliste !
(global-set-key "\M-/" 'dabbrev-expand)
;; (global-set-key "\M-/" 'hippie-expand)

;; ----------------------
;; * disable insert key *
(global-set-key (kbd "<insert>")
                (lambda nil
                  (interactive)
                  (message "Insert is desabled. Use \"M-x overwrite-mode\" instead")))

;; ----------------------------
;; * C-f1 toggle the menu bar *
(global-set-key (kbd "<C-f1>") 'menu-bar-mode)

;; ------------------------
;; * Pour créer une macro *
;; Début de définition d'une macro
(if (fboundp 'kmacro-start-macro)
    (global-set-key (kbd "S-<f4>") 'kmacro-start-macro)
  ;; Termine la définition en cours sinon execute la dernière.
  (global-set-key (kbd "<f4>") 'kmacro-end-or-call-macro)
  ;; Edite la dernière macro
  (global-set-key (kbd "<C-f4>") 'kmacro-edit-macro))

;; Bascule du mode abbrev-mode
(global-set-key (kbd "<f7>") 'abbrev-mode)

;; Local variables:
;; coding: utf-8
;; End:
