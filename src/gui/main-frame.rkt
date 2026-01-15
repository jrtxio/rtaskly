#lang racket/gui

;; Main window module - defines the application's main frame
;; Includes menu bar, sidebar, task panel, and status bar

(require "sidebar.rkt"
         "task-panel.rkt"
         "language.rkt"
         "dialogs.rkt"
         "../core/database.rkt"
         "../utils/path.rkt"
         racket/runtime-path)

;; Define runtime path for icons directory
(define-runtime-path icons-path "../../icons")

(provide main-frame%)

;; Version number
(define (get-app-version) "0.0.26")

;; Main window class
(define main-frame%
  (class frame%
    (init [db-path #f])
    (super-new [label (translate "Taskly")]
               [min-width 850]
               [min-height 650])
    
    ;; Try to set window icon
    (define (set-window-icon)
      ;; Try different icon sizes, prioritize small sizes suitable for title bar
      ;; Prioritize ICO format as it natively supports transparency and multiple sizes
      (define icon-paths
        (list
         (build-path icons-path "16x16.ico")
         (build-path icons-path "32x32.ico")
         (build-path icons-path "16x16.png")
         (build-path icons-path "32x32.png")
         (build-path icons-path "taskly.png")))
      
      (define (try-set-icon paths)
        (when (not (null? paths))
          (define icon-path (car paths))
          (if (file-exists? icon-path)
              (let ([icon-bitmap (make-object bitmap% icon-path)])
                (send this set-icon icon-bitmap))
              (try-set-icon (cdr paths)))))
      
      (try-set-icon icon-paths))
    
    ;; Set window icon
    (set-window-icon)
    
    ;; Save initialization parameters
    (define init-db-path db-path)
    
    ;; Global state
    (define current-view (make-parameter "list")) ; "list", "today", "planned", "all", "completed", "search"
    (define current-list-id (make-parameter #f))
    (define current-list-name (make-parameter ""))
    (define current-search-keyword (make-parameter #f))
    (define db-connected? (make-parameter #f))
    (define current-db-path (make-parameter #f))
    
    ;; Create menu bar
    (define menubar (new menu-bar% [parent this]))
    
    ;; Create file menu
    (define file-menu (new menu% [parent menubar] [label (translate "File")]))
    
    ;; New database menu item
    (new menu-item%
         [parent file-menu]
         [label (translate "New Database")]
         [shortcut #\n] ; n
         [shortcut-prefix '(ctl)]
         [callback (lambda (menu-item event) 
                     (show-new-database-dialog))])
    
    ;; Open database menu item
    (new menu-item%
         [parent file-menu]
         [label (translate "Open Database")]
         [shortcut #\o] ; o
         [shortcut-prefix '(ctl)]
         [callback (lambda (menu-item event) 
                     (show-open-database-dialog))])
    
    ;; Close database menu item
    (new menu-item%
         [parent file-menu]
         [label (translate "Close Database")]
         [callback (lambda (menu-item event) 
                     (disconnect-database))])
    
    ;; Separator
    (new separator-menu-item% [parent file-menu])
    
    ;; Exit menu item
    (new menu-item%
         [parent file-menu]
         [label (translate "Exit")]
         [shortcut #\q] ; q
         [shortcut-prefix '(ctl)]
         [callback (lambda (menu-item event) 
                     (exit))])
    
    ;; Create settings menu
    (define settings-menu (new menu% [parent menubar] [label (translate "Settings")]))
    
    ;; Create language submenu
    (define language-menu (new menu% [parent settings-menu] [label (translate "Language")]))
    
    ;; Chinese menu item
    (new menu-item%
         [parent language-menu]
         [label (translate "Chinese")]
         [callback (lambda (menu-item event) 
                     (set-language! "zh")
                     (save-language-setting)
                     (refresh-interface))])
    
    ;; English menu item
    (new menu-item%
         [parent language-menu]
         [label (translate "English")]
         [callback (lambda (menu-item event) 
                     (set-language! "en")
                     (save-language-setting)
                     (refresh-interface))])
    
    ;; Create help menu
    (define help-menu (new menu% [parent menubar] [label (translate "Help")]))
    
    ;; About menu item
    (new menu-item%
         [parent help-menu]
         [label (translate "About")]
         [callback (lambda (menu-item event) 
                     (show-about-dialog))])
    
    ;; Create main vertical panel, containing main panel and status bar
    (define main-vertical-panel (new vertical-panel%
                                     [parent this]
                                     [spacing 0]
                                     [border 0]
                                     [stretchable-width #t]
                                     [stretchable-height #t]))
    
    ;; Create main panel
    (define main-panel (new horizontal-panel%
                            [parent main-vertical-panel]
                            [spacing 0]
                            [border 0]
                            [stretchable-height #t]))
    
    ;; Create sidebar
    (define sidebar (new sidebar% [parent main-panel]
                         [on-view-change (lambda (view-type [list-id #f] [list-name #f])
                                           (current-view view-type)
                                           (when list-id (current-list-id list-id))
                                           (when list-name (current-list-name list-name))
                                           (current-search-keyword #f)
                                           (send task-panel update-tasks view-type list-id list-name)
                                           (show-status-message (translate "Switched to \"~a\" view" list-name))
                                           ;; Save current selected list ID to config file
                                           (when (and list-id (equal? view-type "list"))
                                             (set-config "last-selected-list-id" (number->string list-id))))]
                         [on-task-updated (lambda ()
                                            (send task-panel update-tasks (current-view) (current-list-id) (current-list-name) (current-search-keyword)))]))
    
    ;; Ensure sidebar is properly sized
    (send sidebar min-height 600)
    
    ;; Create divider
    (define divider (new canvas%
                         [parent main-panel]
                         [min-width 1]
                         [stretchable-width #f]
                         [stretchable-height #t]
                         [paint-callback
                          (lambda (canvas dc)
                            (define-values (w h) (send canvas get-size))
                            (send dc set-pen (make-object color% 209 209 214) 1 'solid)
                            (send dc draw-line 0 0 0 h))]))
    
    ;; Create task panel
    (define task-panel (new task-panel%
                            [parent main-panel]
                            [on-task-updated (lambda ()
                                               (send sidebar refresh-lists)
                                               (send task-panel update-tasks (current-view) (current-list-id) (current-list-name) (current-search-keyword)))]))
    
    ;; Create status bar
    (define status-bar (new horizontal-panel%
                           [parent main-vertical-panel]
                           [stretchable-height #f]
                           [stretchable-width #t]
                           [spacing 4]
                           [border 2]
                           [style '(border)]))
    
    ;; Create status message label
    (define status-message-label (new message%
                               [parent status-bar]
                               [label (translate "Ready")]
                               [font (make-font #:size 11 #:family 'modern)]
                               [stretchable-width #t]))
    
    ;; Show new database dialog
    (define (show-new-database-dialog)
      (define dialog (new dialog%
                          [label (translate "New Database File")]
                          [parent this]
                          [width 500]
                          [height 300]))
      
      (define panel (new vertical-panel% [parent dialog] [spacing 10] [border 10]))
      
      (new message% [parent panel] [label (translate "Please enter the path and name for the new database file.")])
      
      (define file-panel (new horizontal-panel% [parent panel] [spacing 10]))
      
      (define file-field (new text-field%
                              [parent file-panel]
                              [label ""]
                              [init-value (path->string (get-default-db-path))]
                              [stretchable-width #t]))
      
      ;; Browse button callback
      (define (browse-callback btn evt)
        (define selected-file (put-file (translate "Save database file")))
        (when selected-file
          ;; Check and add .db extension
          (define final-path (if (equal? #".db" (path-get-extension selected-file))
                                 selected-file
                                 (path-add-extension selected-file #".db")))
          (send file-field set-value (path->string final-path))))
      
      (new button%
           [parent file-panel]
           [label (translate "Browse...")]
           [callback browse-callback])
      
      (define button-panel (new horizontal-panel% [parent panel] [spacing 10] [alignment '(center center)]))
      
      (define (ok-callback)
        (define file-path (send file-field get-value))
        (when (not (equal? (string-trim file-path) ""))
          ;; Check and add .db extension
          (define path (string->path file-path))
          (define final-path (if (equal? #".db" (path-get-extension path))
                                 path
                                 (path-add-extension path #".db")))
          (send dialog show #f)
          (connect-to-db (path->string final-path))))
      
      (new button%
           [parent button-panel]
           [label (translate "OK")]
           [min-width 80]
           [callback (lambda (btn evt) (ok-callback))])
      
      (new button%
           [parent button-panel]
           [label (translate "Cancel")]
           [min-width 80]
           [callback (lambda (btn evt) (send dialog show #f))])
      
      (send dialog show #t))
    
    ;; Show open database dialog
    (define (show-open-database-dialog)
      (define selected-file (get-file (translate "Select database file")))
      (when selected-file
        (connect-to-db (path->string selected-file))))

    ;; Connect to database
    (define (connect-to-db db-path)
      (with-handlers ([exn:fail? (lambda (e) 
                                   (show-status-message (format "Database connection error: ~a" (exn-message e)))
                                   (eprintf "Database connection error: ~a\n" (exn-message e)))])
        ;; Ensure directory exists
        (ensure-directory-exists (path-only (string->path db-path)))
        
        ;; Connect to database
        (connect-to-database db-path)
        
        ;; Update status
        (db-connected? #t)
        (current-db-path db-path)
        
        ;; Save config, record last selected database path
        (set-config "last-db-path" db-path)
        
        ;; Update interface
        (send sidebar refresh-lists)
        (send task-panel update-tasks (current-view) (current-list-id) (current-list-name))
        
        ;; Update window title
        (update-title)
        
        ;; Show status message
        (show-status-message (translate "Database connected successfully"))))
    
    ;; Disconnect database
    (define (disconnect-database) 
      (with-handlers ([exn:fail? (lambda (e) 
                                   (show-status-message (format "Error closing database: ~a" (exn-message e)))
                                   (eprintf "Error closing database: ~a\n" (exn-message e)))])
        (when (db-connected?) 
          (close-database)
          (db-connected? #f)
          (current-db-path #f)
          ;; Update interface
          (send sidebar refresh-lists)
          (send task-panel update-tasks (current-view) (current-list-id) (current-list-name))
          
          ;; Update window title
          (update-title)
          
          ;; Show status message
          (show-status-message (translate "Database closed")))))
    
    ;; Update window title
    (define (update-title)
      (define title
        (if (current-db-path)
            (let* ([db-path (string->path (current-db-path))]
                   [file-name (path->string (file-name-from-path db-path))])
              (format "~a (~a) - Taskly" file-name (current-db-path)))
            "Taskly"))
      (send this set-label title))
    
    ;; Show about dialog
    (define (show-about-dialog)
      (define dialog (new dialog%
                          [label (translate "About Taskly")]
                          [parent this]
                          [width 300]
                          [height 200]))
      
      (define panel (new vertical-panel% [parent dialog] [spacing 15] [border 20] [alignment '(center center)]))
      
      (new message% [parent panel] [label (translate "Taskly")] [font (make-font #:weight 'bold #:size 18)])
      (new message% [parent panel] [label (format "V~a" (get-app-version))])
      (new message% [parent panel] [label (translate "Minimal local task management tool")])
      (new message% [parent panel] [label (translate "Fully localized, user controls data")])
      
      (define button-panel (new horizontal-panel% [parent panel] [spacing 10] [alignment '(center center)]))
      
      (new button%
           [parent button-panel]
           [label (translate "OK")]
           [min-width 80]
           [callback (lambda (btn evt) (send dialog show #f))])
      
      (send dialog show #t))
    
    ;; Refresh interface language
    (define (refresh-interface)
      ;; Update window title
      (update-title)
      
      ;; Update menu labels
      (send file-menu set-label (translate "File"))
      (send settings-menu set-label (translate "Settings"))
      (send language-menu set-label (translate "Language"))
      (send help-menu set-label (translate "Help"))
      
      ;; Define menu label mappings
      (define file-menu-mapping
        '("New Database" "Open Database" "Close Database" "Exit"))
      
      (define help-menu-mapping
        '("About"))
      
      (define language-menu-mapping
        '("Chinese" "English"))
      
      ;; Update file menu items
      (let ([items (send file-menu get-items)]
            [mapping-index 0])
        (for ([item items])
          (when (and (is-a? item menu-item%)
                     (< mapping-index (length file-menu-mapping)))
            (let ([key (list-ref file-menu-mapping mapping-index)])
              (send item set-label (translate key))
              (set! mapping-index (+ mapping-index 1))))))
      
      ;; Update help menu items
      (let ([items (send help-menu get-items)]
            [mapping-index 0])
        (for ([item items])
          (when (and (is-a? item menu-item%)
                     (< mapping-index (length help-menu-mapping)))
            (let ([key (list-ref help-menu-mapping mapping-index)])
              (send item set-label (translate key))
              (set! mapping-index (+ mapping-index 1))))))
      
      ;; Update language menu items
      (let ([items (send language-menu get-items)]
            [mapping-index 0])
        (for ([item items])
          (when (and (is-a? item menu-item%)
                     (< mapping-index (length language-menu-mapping)))
            (let ([key (list-ref language-menu-mapping mapping-index)])
              (send item set-label (translate key))
              (set! mapping-index (+ mapping-index 1))))))
      
      ;; Update language elements first
      (send sidebar update-language)
      (send task-panel update-language)
      
      ;; Then refresh lists and tasks with updated language
      (send sidebar refresh-lists)
      (send sidebar set-selected-button (send sidebar get-current-selected-btn))
      
      (send task-panel update-tasks (current-view) (current-list-id) (current-list-name))
      
      ;; Update status bar
      (show-status-message (translate "Ready")))
    
    ;; Initialize application
    (define/public (init-app)
      ;; Load language setting
      (load-language-setting)
      
      (when init-db-path
        (connect-to-db init-db-path))
      
      ;; Update window title
      (update-title)
      
      ;; Refresh interface language
      (refresh-interface)
      
      ;; Final refresh to ensure all lists are displayed
      (send sidebar refresh-lists)
      (send task-panel update-tasks (current-view) (current-list-id) (current-list-name))
      
      ;; Show status message
      (show-status-message (translate "Application initialized successfully")))
    
    ;; Expose methods for external calls
    (define/public (get-current-view) (current-view))
    (define/public (get-current-list-id) (current-list-id))
    (define/public (get-current-list-name) (current-list-name))
    (define/public (get-current-search-keyword) (current-search-keyword))
    (define/public (is-db-connected?) (db-connected?))
    (define/public (show-status-message msg [duration 3000])
      ;; Use queue-callback to ensure GUI update in main thread
      (queue-callback (lambda ()
                        (send status-message-label set-label msg)))
      ;; Restore default state after 3 seconds
      (thread (lambda ()
                (sleep (* duration 0.001))
                ;; Use queue-callback to ensure GUI update in main thread
                (queue-callback (lambda ()
                                  (send status-message-label set-label (translate "Ready")))))))
    
    (void)))
