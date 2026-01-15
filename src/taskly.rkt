#lang racket/gui

;; Taskly main application entry point
;; Responsible for initializing the application, displaying the database selection dialog, and starting the main window

(require racket
         racket/gui/base
         racket/runtime-path
         "core/database.rkt"
         "gui/main-frame.rkt"
         "gui/language.rkt"
         "utils/path.rkt")

;; Define runtime path for icons directory
(define-runtime-path icons-path "../icons")

;; Global application state
(define app-frame #f)

;; Display database file selection dialog, return selected file path
(define (show-db-file-dialog)
  ;; Load user's language setting
  (load-language-setting)
  
  ;; Set fixed window size - use stretchable parameters to prevent resizing
  (define dialog (new dialog%
                      [label (translate "Welcome to Taskly")]
                      [width 500]
                      [height 200]
                      [min-width 500]
                      [min-height 200]
                      [stretchable-width #f]
                      [stretchable-height #f]))
  
  ;; Try to set dialog icon
  (define (set-dialog-icon)
    ;; Try different icon sizes, prioritize small sizes suitable for title bar
    ;; Prioritize ICO format as it natively supports transparency and multiple sizes
    (define icon-paths
      (list (build-path icons-path "16x16.ico")
            (build-path icons-path "32x32.ico")
            (build-path icons-path "16x16.png")
            (build-path icons-path "32x32.png")
            (build-path icons-path "taskly.png")))
    
    ;; Find first existing icon file and set it
    (for/first ([icon-path icon-paths] #:when (file-exists? icon-path))
      (send dialog set-icon (make-object bitmap% icon-path))))
  
  (set-dialog-icon)
  
  ;; Main panel
  (define main-panel (new vertical-panel% [parent dialog] [spacing 25] [border 30]))
  
  ;; Prompt message
  (new message% [parent main-panel]
       [label (translate "Please select or create a task database")]
       [font (make-object font% 12 'default 'normal 'normal)])
  
  ;; File selection area
  (define file-panel (new horizontal-panel% [parent main-panel] [spacing 10]))
  (define file-field (new text-field% [parent file-panel]
                          [label ""]
                          [init-value (path->string (get-default-db-path))]
                          [stretchable-width #t]))
  
  ;; Browse button callback
  (new button% [parent file-panel]
       [label (translate "Browse...")]
       [callback (lambda (btn evt)
                  (define selected-file (get-file (translate "Select database file")))
                  (when selected-file
                    (send file-field set-value (path->string selected-file))))])
  
  ;; Button area
  (define button-panel (new horizontal-panel% [parent main-panel] [spacing 20] [alignment '(center center)]))
  
  ;; OK button callback
  (define result #f)
  (new button% [parent button-panel]
       [label (translate "OK")]
       [min-width 80]
       [callback (lambda (btn evt)
                  (define file-path (send file-field get-value))
                  (when (non-empty-string? (string-trim file-path))
                    (set! result file-path)
                    (send dialog show #f)))])
  
  (new button% [parent button-panel]
       [label (translate "Cancel")]
       [min-width 80]
       [callback (lambda (btn evt) (send dialog show #f))])
  
  (send dialog show #t)
  result)

;; Run application
(define (run-app [db-path #f])
  (when db-path
    (set! app-frame (new main-frame% [db-path db-path]))
    (send app-frame init-app)
    (send app-frame center)
    (send app-frame show #t)))

;; Main program entry
(define (main)
  ;; Read last selected database path
  (define last-db-path (get-config "last-db-path"))
  
  ;; If there's a last selected path and the file exists, use it directly; otherwise show selection dialog
  (define db-path (or (and last-db-path (file-exists? last-db-path) last-db-path)
                      (show-db-file-dialog)))
  
  (run-app db-path))

;; Start application
(main)