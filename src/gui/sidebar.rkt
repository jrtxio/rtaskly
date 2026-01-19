#lang racket/gui

;; Sidebar module - defines the application's side navigation bar
;; Includes smart list buttons and custom list management functionality

(require (prefix-in core: "../core/list.rkt")
         (prefix-in task: "../core/task.rkt")
         "language.rkt"
         "../utils/path.rkt"
         "../utils/font.rkt"
         racket/draw)

(provide sidebar%)

;; Custom button class with selected state support
(define custom-button%
  (class button%
    (init parent
          [label ""]
          [callback (lambda (btn evt) (void))]
          [min-width 0]
          [min-height 0]
          [font #f])
    
    (super-new [parent parent]
               [label label]
               [callback callback]
               [min-width min-width]
               [min-height min-height]
               [font font]
               [stretchable-width #t])
    
    ;; Original label without selection indicator
    (define original-label label)
    
    ;; Selected state
    (define selected? #f)
    
    ;; Get selected state
    (define/public (is-selected?)
      selected?)
    
    ;; Set selected state
    (define/public (set-selected! state)
      (set! selected? state)
      ;; Update button label with or without selection indicator
      (if selected?
          (send this set-label (string-append "→ " original-label))
          (send this set-label original-label)))
    
    ;; Set original label
    (define/public (set-original-label! new-label)
      (set! original-label new-label)
      ;; Update current label with selection indicator if needed
      (send this set-selected! selected?))
  )
)

;; Sidebar class
(define sidebar%
  (class vertical-panel%
    (init parent
          [on-view-change (lambda (view-type [list-id #f] [list-name #f]) (void))]
          [on-task-updated (lambda () (void))]
          [auto-select-first-list #t])
    
    (super-new [parent parent]
               [min-width 250]
               [spacing 6]
               [border 6]
               [stretchable-width #f]
               [stretchable-height #t])
    
    ;; Callback functions
    (define view-change-callback on-view-change)
    (define task-updated-callback on-task-updated)
    (define auto-select-first-list? auto-select-first-list)
    
    ;; List buttons list
    (define list-buttons '())
    
    ;; Currently selected button and original label
    (define current-selected-btn #f)
    (define current-selected-original-label #f)
    
    ;; Currently selected list ID and name
    (define current-selected-list-id #f)
    (define current-selected-list-name #f)
    
    ;; Set selected button
    (define/public (set-selected-button btn [list-id #f] [list-name #f])
      ;; Restore previous selected button's state
      (when current-selected-btn
        (send current-selected-btn set-selected! #f)
        (send current-selected-btn refresh))
      
      ;; Set new selected button
      (set! current-selected-btn btn)
      (set! current-selected-list-id list-id)
      (set! current-selected-list-name list-name)
      
      ;; Set selected style if button exists
      (when btn
        (send btn set-selected! #t)
        (send btn refresh))
    )
    
    ;; Create smart lists panel
    (define smart-lists-panel (new vertical-panel%
                                   [parent this]
                                   [stretchable-height #f]
                                   [spacing 4]
                                   [border 4]))
    
    ;; Create first row horizontal panel
    (define smart-lists-row1 (new horizontal-panel%
                                  [parent smart-lists-panel]
                                  [stretchable-height #f]
                                  [spacing 4]
                                  [stretchable-width #t]
                                  [alignment '(left center)]))
    
    ;; Today button
    (define today-btn
      (new custom-button%
           [parent smart-lists-row1]
           [label (translate "Today")]
           [min-width 120]
           [min-height 36]
           [font (create-button-font)]
           [callback (lambda (btn evt) 
                       (set-selected-button btn #f (translate "Today"))
                       (view-change-callback "today" #f (translate "Today")))]))
    
    ;; Planned button
    (define planned-btn
      (new custom-button%
           [parent smart-lists-row1]
           [label (translate "Planned")]
           [min-width 120]
           [min-height 36]
           [font (create-button-font)]
           [callback (lambda (btn evt) 
                       (set-selected-button btn #f (translate "Planned"))
                       (view-change-callback "planned" #f (translate "Planned")))]))
    
    ;; Create second row horizontal panel
    (define smart-lists-row2 (new horizontal-panel%
                                  [parent smart-lists-panel]
                                  [stretchable-height #f]
                                  [spacing 4]
                                  [stretchable-width #t]
                                  [alignment '(left center)]))
    
    ;; All button
    (define all-btn
      (new custom-button%
           [parent smart-lists-row2]
           [label (translate "All")]
           [min-width 120]
           [min-height 36]
           [font (create-button-font)]
           [callback (lambda (btn evt) 
                       (set-selected-button btn #f (translate "All"))
                       (view-change-callback "all" #f (translate "All")))]))
    
    ;; Completed button
    (define completed-btn
      (new custom-button%
           [parent smart-lists-row2]
           [label (translate "Completed")]
           [min-width 120]
           [min-height 36]
           [font (create-button-font)]
           [callback (lambda (btn evt) 
                       (set-selected-button btn #f (translate "Completed"))
                       (view-change-callback "completed" #f (translate "Completed")))]))
    
    ;; Create custom lists panel
    (define my-lists-panel (new vertical-panel% 
                              [parent this] 
                              [spacing 2] 
                              [stretchable-height #t]
                              [stretchable-width #t]))
    
    ;; Lists title
    (define my-lists-label (new message% 
                                [parent my-lists-panel] 
                                [label (translate "My Lists")] 
                                [font (create-bold-medium-font)] 
                                [stretchable-width #t]))
    
    ;; Create lists container
    (define lists-container (new vertical-panel% 
                                 [parent my-lists-panel] 
                                 [spacing 2] 
                                 [stretchable-height #t]
                                 [stretchable-width #t]
                                 [min-height 150]))
    
    ;; List management panel (bottom left)
    (define list-management-panel (new horizontal-panel%
                                      [parent my-lists-panel]
                                      [stretchable-height #f]
                                      [spacing 4]
                                      [alignment '(center center)]))
    
    ;; Create add list button
    (define add-list-btn
      (new button%
           [parent list-management-panel]
           [label "+"]
           [min-width 40]
           [min-height 32]
           [font (create-button-font)]
           [callback (lambda (btn evt) (void))]))
    
    ;; Create delete list button
    (define delete-list-btn
      (new button%
           [parent list-management-panel]
           [label "-"]
           [min-width 40]
           [min-height 32]
           [font (create-button-font)]
           [callback (lambda (btn evt) (void))]))
    
    ;; Refresh lists
    (define/public (refresh-lists)
      ;; Clear custom lists container
      (send lists-container change-children (lambda (children) '()))
      
      
      
      ;; Try to get lists with detailed error handling
      (define all-lists '())
      (with-handlers ([exn:fail? (lambda (e) 
                                   '())])
        (set! all-lists (core:get-all-lists)))
      
      
      
      ;; Add custom list buttons
      (for ([lst all-lists])
        (define list-id (core:todo-list-id lst))
        (define list-name (core:todo-list-name lst))
        
        
        
        (new custom-button% [parent lists-container]
             [label list-name]
             [min-width 120]
             [min-height 32]
             [font (create-button-font)]
             [callback (lambda (btn evt) 
                         (set-selected-button btn list-id list-name)
                         (view-change-callback "list" list-id list-name))]))
    )
    
    ;; Initial state: disable all functionality
    (refresh-lists)
    
    ;; Public method: get smart list buttons
    (define/public (get-smart-list-buttons)
      (list today-btn planned-btn all-btn completed-btn))
    
    ;; Public method: get custom list buttons
    (define/public (get-custom-list-buttons)
      ;; Get children directly from container to ensure latest button list
      (send lists-container get-children))
    
    ;; Public method: get current selected button
    (define/public (get-current-selected-btn)
      current-selected-btn)
    
    ;; Public method: get current selected button's original label
    (define/public (get-current-selected-original-label)
      current-selected-original-label)
    
    ;; Public method: update language elements
    (define/public (update-language)
      ;; Update smart list buttons
      (send today-btn set-original-label! (translate "Today"))
      (send planned-btn set-original-label! (translate "Planned"))
      (send all-btn set-original-label! (translate "All"))
      (send completed-btn set-original-label! (translate "Completed"))
      
      ;; Update my lists label
      (send my-lists-label set-label (translate "My Lists")))
    
    (void)
  )
)
