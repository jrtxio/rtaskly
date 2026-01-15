#lang racket/gui

;; Task panel module - defines task input controls and task list display
;; Includes custom task input control and task panel class

(require "dialogs.rkt"
         (prefix-in task: "../core/task.rkt")
         (prefix-in core: "../core/list.rkt")
         (prefix-in date: "../utils/date.rkt")
         "../utils/font.rkt"
         "language.rkt")

;; Task rendering canvas class, implementing automatic line wrapping and strikethrough effect
(define task-render-canvas%
  (class canvas%
    (init-field task-text task-completed?)
    (inherit get-dc get-client-size min-height refresh)
    
    ;; Dynamic line wrapping algorithm
    (define (get-lines dc max-w txt)
      (if (<= max-w 40) '([""])
          (let ([chars (map string (string->list txt))] [ls '()] [curr ""])
            (for ([c chars])
              (define-values (cw ch cd ca) (send dc get-text-extent (string-append curr c)))
              ;; Windows system: slightly increase margin to prevent pixel overflow
              (if (> cw (- max-w 28)) 
                  (begin (set! ls (append ls (list curr))) (set! curr c))
                  (set! curr (string-append curr c))))
            (append ls (list curr)))))

    (define/override (on-paint)
      (define dc (get-dc))
      (define-values (w h) (get-client-size))
      
      ;; Rendering optimization core:
      (send dc set-smoothing 'smoothed)    ;; Enable smoothing
      (send dc set-text-mode 'solid)       ;; Key: set to solid mode to reduce edge blurring on Windows
      
      ;; Manually clean background to provide clean base for font rendering
      (send dc set-background (make-object color% 255 255 255))
      (send dc clear)
      
      ;; Set color: completed task color slightly darker to ensure visibility on Windows
      (define text-color (if task-completed? 
                             (make-object color% 160 160 160) 
                             (make-object color% 30 30 30)))
      (send dc set-text-foreground text-color)
      
      ;; 使用统一的任务文本字体
      (send dc set-font (create-task-text-font task-completed?))
      
      (define lines (get-lines dc w task-text))
      (define line-h 24)
      
      (for ([line lines] [i (in-naturals)])
        (define y-pos (+ 6 (* i line-h)))
        (send dc draw-text line 5 y-pos)
        
        ;; Render strikethrough
        (when task-completed?
          (define-values (lw lh ld la) (send dc get-text-extent line))
          (send dc set-pen text-color 1 'solid)
          (define middle-y (+ y-pos 13))
          (send dc draw-line 5 middle-y (+ 5 lw) middle-y)))
      
      ;; Dynamic height feedback
      (define total-h (+ 12 (* (length lines) line-h)))
      (when (not (= (min-height) (exact-round total-h)))
        (min-height (exact-round total-h))))

    (define/override (on-size w h) (refresh))
    (super-new [style '(no-autoclear)])))

(provide parse-task-input
         task-panel%
         task-input%)

;; Custom task input control, supporting placeholder and Enter key submission
(define task-input%
  (class editor-canvas%
    (init-field [placeholder ""] [callback (λ (t) (void))])
    
    ;; Disable scrollbars
    (super-new [style '(no-hscroll no-vscroll)])
    
    ;; Track text changes to hide placeholder
    (define showing-placeholder? #t)
    
    ;; Set font
    (define font (create-task-input-font))
    
    (define text (new text%))
    (send this set-editor text)
    
    ;; Key: make editor editable
    (send text lock #f)
    
    ;; Set font style
    (define style-delta (new style-delta%))
    (send style-delta set-delta 'change-size default-font-size)
    (send text change-style style-delta)
    
    ;; Handle Enter key submission
    (define/override (on-char event)
      (cond
        [(equal? (send event get-key-code) #\return)
         (define content (send text get-text))
         ;; Only process non-empty content
         (unless (string=? (string-trim content) "")
           (callback content)
           (send text erase)
           (set! showing-placeholder? #t)
           (send this refresh))]
        [else
         (super on-char event)
         (set! showing-placeholder? (= (send text last-position) 0))
         (send this refresh)]))
    
    (define/override (on-paint)
      (super on-paint)
      (define dc (send this get-dc))
      (define-values (w h) (send this get-client-size))
      
      (define has-focus? (send this has-focus?))
      
      ;; Draw square border
      (if has-focus? 
          (send dc set-pen (make-object color% 0 120 255) 2 'solid) 
          (send dc set-pen (make-object color% 200 200 200) 1 'solid))
      
      (send dc set-brush "white" 'transparent)
      (send dc draw-rectangle 0 0 w h)
      
      ;; Draw placeholder, vertically centered
      (when (and showing-placeholder? (not has-focus?))
        (send dc set-text-foreground (make-object color% 160 160 160))
        (send dc set-font font)
        ;; Calculate vertical center position for text
        (define-values (text-width text-height ascent descent) 
          (send dc get-text-extent placeholder font))
        (define text-y (quotient (- h text-height) 2))
        (send dc draw-text placeholder 10 text-y)))
    
    (define/override (on-focus on?)
      (super on-focus on?)
      (send this refresh))
    
    ;; Provide method to clear input
    (define/public (clear-input)
      (send text erase)
      (set! showing-placeholder? #t)
      (send this refresh))
    
    ;; Provide method to get content
    (define/public (get-content)
      (send text get-text))
    
    ;; Provide method to set placeholder
    (define/public (set-placeholder new-placeholder)
      (set! placeholder new-placeholder)
      (when showing-placeholder?
        (send this refresh)))
)
)

;; Parse task input, extract task description and due date
(define (parse-task-input input-str)
  (let ([trimmed (string-trim input-str)])
    ;; Find position of time modifier
    (define modifier-match
      (or (regexp-match-positions #rx" [+@][0-9]+" trimmed)
          (regexp-match-positions #rx"[+@][0-9]+" trimmed)))
    
    (if modifier-match
        ;; Has time modifier
        (let* ([modifier-start (caar modifier-match)]
               [task-text (string-trim (substring trimmed 0 modifier-start))]
               [modifier (string-trim (substring trimmed modifier-start))]
               [parsed-date (date:parse-date-string modifier)])
          (values task-text parsed-date))
        ;; No time modifier
        (values trimmed #f))
  )
)

;; Create task panel class
(define task-panel%
  (class vertical-panel%
    (init parent [on-task-updated (lambda () (void))])
    
    (super-new [parent parent] [spacing 0] [border 0] [stretchable-height #t])
    
    ;; Callback function
    (define task-updated-callback on-task-updated)
    
    ;; Current state
    (define current-view (make-parameter "list"))
    (define current-list-id (make-parameter #f))
    (define current-list-name (make-parameter ""))
    
    ;; Handle quick add task
    (define (handle-quick-add-task input-str)
      (define-values (task-text due-date) (parse-task-input input-str))
      (when (not (string=? (string-trim task-text) ""))
        ;; Get current selected list ID or default list
        (define list-id (or (current-list-id)
                          (let ([default-list (core:get-default-list)])
                            (if default-list
                                (core:todo-list-id default-list)
                                (let ([all-lists (core:get-all-lists)])
                                  (if (not (empty? all-lists))
                                      (core:todo-list-id (first all-lists))
                                      #f))))))
        
        (when list-id
          ;; Add task
          (task:add-task list-id task-text due-date)
          ;; Call callback to update interface
          (task-updated-callback))))
    
    ;; Quick add task input box - placed at the top
    (define quick-task-input
      (new task-input%
           [parent this] ;; Directly as child component of task-panel
           [min-width 300] ;; Increase minimum width
           [min-height 30] ;; Fixed minimum height
           [stretchable-width #t] ;; Full width display
           [stretchable-height #f] ;; Disable vertical stretching
           [placeholder (translate "Add new task...")]
           [callback (lambda (content)
                       (handle-quick-add-task content))]))
    
    ;; Create top horizontal panel (only contains title)
    (define top-panel (new horizontal-panel%
                           [parent this]
                           [stretchable-height #f]
                           [spacing 4]
                           [border 4]
                           [stretchable-width #t]))
    
    ;; Create title label
    (define title-label (new message% 
                            [parent top-panel] 
                            [label ""][vert-margin 10][font (create-bold-xlarge-font)][stretchable-width #t]))
    
    ;; Create task scroll panel
    (define task-scroll (new panel% [parent this] [style '(vscroll)] [stretchable-width #t]))
    
    (define task-list-panel (new vertical-panel%
                            [parent task-scroll]
                            [min-width 1]
                            [stretchable-height #t]
                            [stretchable-width #t]
                            [spacing 2]))
    
    ;; Show welcome message
    (define (show-welcome-message)
      ;; Clear task list
      (send task-list-panel change-children (lambda (children) '()))
      
      ;; Create welcome message panel
      (define welcome-panel (new vertical-panel%
                            [parent task-list-panel]
                            [alignment '(center center)]
                            [stretchable-height #t]
                            [spacing 16]))
      
      (new message% 
           [parent welcome-panel] 
           [label (translate "Welcome to Taskly!")] 
           [font (create-bold-xlarge-font)])
      (new message% 
           [parent welcome-panel] 
           [label (translate "Please create or open a database file to get started")] 
           [font (create-medium-font)])
      (new message% 
           [parent welcome-panel] 
           [label (translate "Instructions:")] 
           [font (create-bold-medium-font)])
      (new message%
           [parent welcome-panel]
           [label (translate "1. Click  File → New Database  to create a new task database")])
      (new message%
           [parent welcome-panel]
           [label (translate "2. Or click  File → Open Database  to use an existing database")])
      
      ;; Disable task input box
      (send quick-task-input enable #f))
    
    ;; Enable interface elements
    (define (enable-interface)
      (send quick-task-input enable #t))
    
    ;; Create single task item
    (define (create-task-item task-data)
      ;; Create task item wrapper panel
      (define wrapper (new vertical-panel% [parent task-list-panel] [border 2] [stretchable-height #f]))
      (define task-item (new horizontal-panel% [parent wrapper]
                           [style '(border)]
                           [border 10]
                           [spacing 12]
                           [stretchable-height #f]
                           [stretchable-width #t]))
      
      ;; Create checkbox
      (new check-box% [parent task-item]
           [label ""]
           [value (task:task-completed? task-data)]
           [stretchable-width #f]
           [stretchable-height #f]
           [callback (lambda (cb evt)
                       (task:toggle-task-completed (task:task-id task-data))
                       (task-updated-callback))])
      
      ;; Create content area
      (define info-panel (new vertical-panel% [parent task-item]
                           [stretchable-width #t]
                           [spacing 4]))
      
      ;; Use task rendering canvas to display task content
      (new task-render-canvas% [parent info-panel]
           [task-text (task:task-text task-data)]
           [task-completed? (task:task-completed? task-data)]
           [stretchable-width #t])
      
      ;; Create metadata display panel
      (define meta-panel (new horizontal-panel% [parent info-panel] [spacing 15]))
      
      ;; Display due date
      (when (task:task-due-date task-data)
        (new message% [parent meta-panel]
             [label (format "📅 ~a" (date:format-date-for-display (task:task-due-date task-data)))]
             [font (create-meta-info-font)]))
      
      ;; Create action area
      (define action-panel (new vertical-panel% [parent task-item]
                              [stretchable-width #f]
                              [alignment '(center center)]))
      
      ;; Edit button
      (new button% [parent action-panel]
           [label "✎"]
           [min-width 35]
           [vert-margin 0]
           [callback (lambda (btn evt) (show-edit-task-dialog task-data task-updated-callback))])
      
      ;; Delete button
      (new button% [parent action-panel]
           [label "✕"]
           [vert-margin 4]
           [min-width 35]
           [callback (lambda (btn evt)
                       ;; Show delete confirmation dialog
                       (define result (message-box (translate "Confirm Delete")
                                                  (translate "Are you sure you want to delete task \"~a\"?" 
                                                               (task:task-text task-data))
                                                  (send btn get-top-level-window)
                                                  '(yes-no)))
                       (when (eq? result 'yes)
                         (task:delete-task (task:task-id task-data))
                         (task-updated-callback)))])
      )
    
    ;; Update task list
    (define/public (update-tasks view-type [list-id #f] [list-name #f] [keyword #f])
      ;; Update current state
      (current-view view-type)
      (when list-id (current-list-id list-id))
      (when list-name (current-list-name list-name))
      
      ;; Update title
      (cond
        [(string=? view-type "search")
         (send title-label set-label (if (and keyword (not (equal? keyword "")))
                                         (translate "Search results: \"~a\"" keyword)
                                         (translate "Search results")))]
        [else
         (send title-label set-label (or list-name ""))])
      
      ;; Clear task list
      (send task-list-panel change-children (lambda (children) '()))
      
      ;; Try to get tasks, handle possible database connection errors
      (define tasks
        (with-handlers ([exn:fail? (lambda (e) #f)])
          (task:get-tasks-by-view view-type list-id keyword)))
      
      (if tasks
          ;; Show task list
          (begin
            (enable-interface)
            ;; Show tasks
            (for ([task-data tasks])
              (create-task-item task-data)))
          ;; Show welcome message
          (show-welcome-message))
    )
    
    (void)
    
    ;; Public method: update language elements
    (define/public (update-language)
      ;; Update task input placeholder
      (send quick-task-input set-placeholder (translate "Add new task...")))))
