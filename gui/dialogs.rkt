#lang racket/gui

(require racket/gui/base
         (prefix-in task: "../core/task.rkt")
         (prefix-in core: "../core/list.rkt")
         (prefix-in date: "../utils/date.rkt")
         "language.rkt")

;; 添加任务对话框
(define (show-add-task-dialog [list-id #f] [list-name #f] [callback (lambda () (void))])
  ;; 如果没有指定列表，获取默认列表
  (define default-list (if list-id
                           (core:get-list-by-id list-id)
                           (core:get-default-list)))
  
  (define default-list-id (if default-list (core:todo-list-id default-list) #f))
  (define default-list-name (if default-list (core:todo-list-name default-list) ""))
  
  ;; 根据是否有明确列表ID调整对话框高度
  (define dialog-height (if list-id 500 600))
  
  (define dialog (new dialog% 
                      [label (translate "添加新任务")]
                      [width 400]
                      [height dialog-height]
                      [stretchable-width #t]
                      [stretchable-height #f]))
  
  (define dialog-panel (new vertical-panel% [parent dialog] [spacing 8] [border 12]))
  
  (new message% [parent dialog-panel] [label (translate "任务描述:")] [stretchable-width #t])
  ;; 创建多行文本编辑器
  (define text-editor (new text%))
  (define text-field (new editor-canvas% 
                         [parent dialog-panel] 
                         [editor text-editor]
                         [min-height 80]
                         [stretchable-height #t]
                         [horizontal-inset 2]
                         [vertical-inset 2]))
  (send text-editor insert "")
  
  (new message% [parent dialog-panel] [label (translate "截止日期 (可选):")] [stretchable-width #t])
  
  ;; 日期输入面板，包含文本框
  (define date-input-panel (new horizontal-panel% [parent dialog-panel] [spacing 4] [stretchable-width #t]))
  (define date-field (new text-field% [parent date-input-panel] [label ""] [init-value ""] [stretchable-width #t] [vert-margin 2]))
  
  ;; 添加优先级选择
  (new message% [parent dialog-panel] [label (translate "优先级:")] [stretchable-width #t])
  (define priority-choices (list (translate "低") (translate "中") (translate "高")))
  (define priority-values '(0 1 2))
  (define priority-choice (new choice% 
                              [parent dialog-panel]
                              [label ""]
                              [choices priority-choices]
                              [selection 1])) ; 默认中等优先级
  
  ;; 仅当没有明确指定列表ID时，显示列表选择控件
  (define selected-list-id default-list-id)
  (unless list-id
    (new message% [parent dialog-panel] [label (translate "任务列表:")] [stretchable-width #t])
    
    ;; 获取所有列表用于下拉选择
    (define all-lists (core:get-all-lists))
    (define list-names (map core:todo-list-name all-lists))
    (define list-ids (map core:todo-list-id all-lists))
    
    (define list-choice (new choice% 
                            [parent dialog-panel]
                            [label ""]
                            [choices list-names]
                            [selection (if default-list-id
                                           (index-of list-ids default-list-id)
                                           0)]))
    
    ;; 更新selected-list-id的获取方式
    (set! selected-list-id (lambda ()
                             (define idx (send list-choice get-selection))
                             (list-ref list-ids idx))))
  
  (define button-panel (new horizontal-panel% [parent dialog-panel] [spacing 8] [alignment '(center top)]))
  
  (define (save-task)
    (define text (send text-editor get-text))
    (define date (send date-field get-value))
    
    ;; 根据selected-list-id的类型获取实际值
    (define final-list-id (if (procedure? selected-list-id)
                             (selected-list-id)
                             selected-list-id))
    
    (when (and text (not (equal? (string-trim text) "")))
      (define parsed-date
        (if (not (equal? (string-trim date) ""))
            (date:parse-date-string (string-trim date))
            #f))
      
      (if (or (not (string-trim date))
              (equal? (string-trim date) "")
              parsed-date)
          (begin
            (task:add-task final-list-id text parsed-date)
            (callback)
            (send dialog show #f))
          (message-box (translate "日期格式错误") 
                       (translate "请输入正确的日期格式，例如: +1d, @10am, 2025-08-07")
                       dialog
                       '(ok)))))
  
  (new button% 
       [parent button-panel]
       [label (translate "确定")]
       [min-width 60]
       [callback (lambda (btn evt) (save-task))])
  
  (new button% 
       [parent button-panel]
       [label (translate "取消")]
       [min-width 60]
       [callback (lambda (btn evt) (send dialog show #f))])
  
  (send text-field focus)
  (send dialog show #t))

;; 编辑任务对话框
(define (show-edit-task-dialog task-data [callback (lambda () (void))])
  (define dialog (new dialog% 
                      [label (translate "编辑任务")]
                      [width 400]
                      [height 500]
                      [stretchable-width #t]
                      [stretchable-height #f]))
  
  (define dialog-panel (new vertical-panel% [parent dialog] [spacing 8] [border 12]))
  
  (new message% [parent dialog-panel] [label (translate "任务描述:")] [stretchable-width #t])
  ;; 创建多行文本编辑器
  (define text-editor (new text%))
  (define text-field (new editor-canvas% 
                         [parent dialog-panel] 
                         [editor text-editor]
                         [min-height 80]
                         [stretchable-height #t]
                         [horizontal-inset 2]
                         [vertical-inset 2]))
  (send text-editor insert (task:task-text task-data))
  
  (new message% [parent dialog-panel] [label (translate "截止日期 (可选):")] [stretchable-width #t])
  
  ;; 日期输入面板，包含文本框
  (define date-input-panel (new horizontal-panel% [parent dialog-panel] [spacing 4] [stretchable-width #t]))
  (define date-field (new text-field% [parent date-input-panel] 
                         [label ""] 
                         [init-value (if (task:task-due-date task-data) 
                                         (task:task-due-date task-data) 
                                         "")] 
                         [stretchable-width #t] [vert-margin 2]))
  
  ;; 添加优先级选择
  (new message% [parent dialog-panel] [label (translate "优先级:")] [stretchable-width #t])
  (define priority-choices (list (translate "低") (translate "中") (translate "高")))
  (define priority-values '(0 1 2))
  (define current-priority (task:task-priority task-data))
  (define priority-choice (new choice% 
                              [parent dialog-panel]
                              [label ""]
                              [choices priority-choices]
                              [selection (index-of priority-values current-priority)]))
  
  (define button-panel (new horizontal-panel% [parent dialog-panel] [spacing 8] [alignment '(center top)]))
  
  (define (save-task)
    (define text (send text-editor get-text))
    (define date (send date-field get-value))
    
    (when (and text (not (equal? (string-trim text) "")))
      (define parsed-date
        (if (not (equal? (string-trim date) ""))
            (date:parse-date-string (string-trim date))
            #f))
      (define selected-priority (list-ref priority-values (send priority-choice get-selection)))
      
      (if (or (not (string-trim date))
              (equal? (string-trim date) "")
              parsed-date)
          (begin
            (task:edit-task (task:task-id task-data) (task:task-list-id task-data) text parsed-date selected-priority)
            (callback)
            (send dialog show #f))
          (message-box (translate "日期格式错误") 
                       (translate "请输入正确的日期格式，例如: +1d, @10am, 2025-08-07")
                       dialog
                       '(ok)))))
  
  (new button% 
       [parent button-panel]
       [label (translate "确定")]
       [min-width 60]
       [callback (lambda (btn evt) (save-task))])
  
  (new button% 
       [parent button-panel]
       [label (translate "取消")]
       [min-width 60]
       [callback (lambda (btn evt) (send dialog show #f))])
  
  (send text-field focus)
  (send dialog show #t))

(provide show-add-task-dialog
         show-edit-task-dialog)
