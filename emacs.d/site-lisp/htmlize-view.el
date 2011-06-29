;;; htmlize-view.el --- View current buffer as html in web browser

;; Copyright (C) 2005 by Lennart Borgman

;; Author: Lennart Borgman
;; Created: Fri Oct 21 00:11:07 2005
;; Version: 0.64
;; Last-Updated: Thu Oct 27 01:19:00 2005
;; Keywords: printing
;; Compatibility: 
;; 
;;
;; Features that might be required by this library:
;;
;;   None
;;
;;
;; You can find htmlize.el at
;;   http://fly.srk.fer.hr/~hniksic/emacs/htmlize.el
;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; To find out more about the GNU General Public License you can visit
;; Free Software Foundation's website http://www.fsf.org/.  Or, write
;; to the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Commentary: 
;; 
;;  This file shows the current buffer in your web browser with all
;;  the colors it has. The purpose is mainly to make it possible to
;;  easily print what you see in Emacs in colors on different
;;  platforms.
;;
;;  Put this file in your load-path and in your .emacs this:
;;
;;      (require 'htmlize-view)
;;      (htmlize-view-add-to-files-menu)
;;
;;  Then just call `htmlize-view-buffer' to show the current buffer in
;;  your web browser.
;; 
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Change log:
;; 
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Code:


(require 'htmlize)

(defvar htmlize-view-kill-view-buffers t
  "If non-nil delete temporary html buffers after sending to browser.")
;; (setq htmlize-view-kill-view-buffers nil)

(defun htmlize-view-buffer(&optional region-only)
  "Convert buffer to html, preserving colors and decoration and view in web browser.
If REGION-ONLY is non-nil then only the region is sent to the web browser."
  (interactive)
  (message "Creating a html version for printing ...")
  (let* ((html-file (htmlize-buffer-to-tempfile region-only)))
    (browse-url-of-file html-file)
    ))

(defun htmlize-buffer-to-tempfile(region-only)
  "Convert buffer to html, preserving colors and decoration and write to a temporary file.
If REGION-ONLY is non-nil then only the region is sent to the web browser.
Return a cons with temporary file name followed by temporary buffer."
  (save-excursion
    (let (;; Just use Fundamental mode for the temp buffer
          magic-mode-alist
          auto-mode-alist
          (html-temp-buffer
           (if (not region-only)
               (htmlize-buffer (current-buffer))
             (let ((start (mark)) (end (point)))
               (or (<= start end)
                   (setq start (prog1 end (setq end start))))
               (htmlize-region start end))))
          (file (htmlize-view-gettemp-file-name)))
      (set-buffer html-temp-buffer)
      (write-file file nil)
      (if htmlize-view-kill-view-buffers (kill-buffer html-temp-buffer))
      file)))

(defcustom htmlize-view-temp-dir temporary-file-directory
  "*The name of a directory for htmlize-view's temporary files.
Such files are generated by functions like
`htmllize-view-buffer'.  You might want to set this to somewhere
with restricted read permissions for privacy's sake."
  :type 'string
  :group 'htmlize)

(defun htmlize-view-gettemp-file-name()
  "Get a temp file name for printing"
  (make-temp-file
   (expand-file-name "htmlize-view" htmlize-view-temp-dir) nil ".htm"))
;;   (unless (file-exists-p "~/htmlize-view-temp")
;;     (make-directory-internal "~/htmlize-view-temp"))
;;   (expand-file-name "~/htmlize-view-temp/~temp-print.html"))

;; (htmlize-view-gettemp-file-name)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; Menus

  (defun htmlize-view-add-to-files-menu()
    "Add \"Quick Print\" entry to file menu."
    (let ((print-menu-spec
	   (list
            ["Pre&view with Web Browser (Color)" (htmlize-view-buffer) t
             :help "Print preview buffer with web browser (color)"
             :key-sequence nil
             ] )))
      (let ((submenu
             (list "Print &Region"
                   :help "Print only region"
                   :active 'mark-active
                   :visible 'mark-active
                   ["Pre&view with Web Browser (Color)" (htmlize-view-buffer t) t
                    :help "Print preview region with web browser (color)"
                    ])))
        (setq print-menu-spec (append print-menu-spec
                                      [["-" nil :visible mark-active]]
                                      (list submenu))))
      (easy-menu-change
       ;; This is a dirty check for Emacs older than 21.3
       (if (fboundp 'cua-mode) '("file") '("files"))
       "Quick Print (to OS Default Printer)"
       print-menu-spec "separator-window") ))

(provide 'htmlize-view)

;;; htmlize-view.el ends here
