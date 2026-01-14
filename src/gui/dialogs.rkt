#lang racket/gui

;; 对话框模块，定义各种任务和列表操作的对话框
;; 包含添加任务、编辑任务等对话框

(require racket/gui/base
         (prefix-in task: "../core/task.rkt")
         (prefix-in core: "../core/list.rkt")
         (prefix-in date: "../utils/date.rkt")
         "language.rkt")

(provide show-add-task-dialog
         show-edit-task-dialog)

;; 添加任务对话框
(define (show-add-task-dialog [list-id #f] [list-name #f] [callback (lambda () (void))])
  ;; 获取所有列表用于下拉选择
  (define all-lists (core:get-all-lists))
  (define list-names (map core:todo-list-name all-lists))
  (define list-ids (map core:todo-list-id all-lists))
  
  ;; 确定默认选择的列表索引
  (define default-selection (if list-id
                                (index-of list-ids list-id)
                                (let ([default-list (core:get-default-list)])
                                  (if default-list
                                      (index-of list-ids (core:todo-list-id default-list))
                                      0))))
  
  (define dialog (new dialog% 
                      [label (translate "添加新任务")]
                      [width 400]
                      [height 600]
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
  
  ;; 添加列表选择
  (new message% [parent dialog-panel] [label (translate "任务列表:")] [stretchable-width #t])
  (define list-choice (new choice% 
                          [parent dialog-panel]
                          [label ""]
                          [choices list-names]
                          [selection default-selection]))
  
  (define button-panel (new horizontal-panel% [parent dialog-panel] [spacing 8] [alignment '(center top)]))
  
  (define (save-task)
    (define text (send text-editor get-text))
    (define date (send date-field get-value))
    (define selected-list-id (list-ref list-ids (send list-choice get-selection)))
    
    (when (and text (not (equal? (string-trim text) "")))
      (define parsed-date
        (if (not (equal? (string-trim date) ""))
            (date:parse-date-string (string-trim date))
            #f))
      
      (if (or (not (string-trim date))
              (equal? (string-trim date) "")
              parsed-date)
          (begin
            (task:add-task selected-list-id text parsed-date)
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
                      [height 600]
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
  
  ;; 添加列表选择
  (new message% [parent dialog-panel] [label (translate "任务列表:")] [stretchable-width #t])
  
  ;; 获取所有列表用于下拉选择
  (define all-lists (core:get-all-lists))
  (define list-names (map core:todo-list-name all-lists))
  (define list-ids (map core:todo-list-id all-lists))
  
  ;; 确定默认选择的列表索引
  (define current-list-id (task:task-list-id task-data))
  (define default-selection (index-of list-ids current-list-id))
  
  (define list-choice (new choice% 
                          [parent dialog-panel]
                          [label ""]
                          [choices list-names]
                          [selection default-selection]))
  
  (define button-panel (new horizontal-panel% [parent dialog-panel] [spacing 8] [alignment '(center top)]))
  
  (define (save-task)
    (define text (send text-editor get-text))
    (define date (send date-field get-value))
    (define selected-list-id (list-ref list-ids (send list-choice get-selection)))
    
    (when (and text (not (equal? (string-trim text) "")))
      (define parsed-date
        (if (not (equal? (string-trim date) ""))
            (date:parse-date-string (string-trim date))
            #f))
      
      (if (or (not (string-trim date))
              (equal? (string-trim date) "")
              parsed-date)
          (begin
            (task:edit-task (task:task-id task-data) selected-list-id text parsed-date)
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
