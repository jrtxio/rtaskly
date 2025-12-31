#lang racket/gui

(require "dialogs.rkt"
         (prefix-in task: "../core/task.rkt")
         (prefix-in core: "../core/list.rkt")
         (prefix-in date: "../utils/date.rkt"))

;; 任务面板类
(define task-panel% 
  (class vertical-panel% 
    (init parent [on-task-updated (lambda () (void))])
    
    (super-new [parent parent]
               [spacing 4]
               [border 4])
    
    ;; 回调函数
    (define task-updated-callback on-task-updated)
    
    ;; 当前状态
    (define current-view (make-parameter "list"))
    (define current-list-id (make-parameter #f))
    (define current-list-name (make-parameter ""))
    
    ;; 创建标题标签
    (define title-label (new message% 
                            [parent this]
                            [label ""]
                            [vert-margin 12]
                            [font (make-font #:size 18 #:weight 'bold #:family 'modern)]))
    
    ;; 创建任务滚动面板
    (define task-scroll (new panel% [parent this] [style '(vscroll)]))
    
    (define task-list-panel (new vertical-panel% 
                                [parent task-scroll]
                                [min-width 1]
                                [stretchable-height #t]
                                [stretchable-width #t]
                                [spacing 2]))
    
    ;; 添加任务按钮
    (new button% 
         [parent this]
         [label "+ 新提醒事项"]
         [min-height 32]
         [callback (lambda (btn evt)
                     (show-add-task-dialog (current-list-id) (current-list-name) task-updated-callback))])
    
    ;; 更新任务列表
    (define/public (update-tasks view-type [list-id #f] [list-name #f])
      ;; 更新当前状态
      (current-view view-type)
      (when list-id (current-list-id list-id))
      (when list-name (current-list-name list-name))
      
      ;; 更新标题
      (send title-label set-label (or list-name ""))
      
      ;; 清空任务列表
      (send task-list-panel change-children (lambda (children) '()))
      
      ;; 获取任务
      (define tasks (task:get-tasks-by-view view-type list-id))
      
      ;; 显示任务
      (for ([task-data tasks])
        ;; 创建任务项
        (define task-item (new horizontal-panel% 
                              [parent task-list-panel]
                              [stretchable-height #f]
                              [stretchable-width #t]
                              [style '(border)]
                              [spacing 8]
                              [border 5]))
        
        ;; 创建复选框
        (new check-box% 
             [parent task-item]
             [label ""]
             [min-width 30]
             [stretchable-width #f]
             [value (task:task-completed? task-data)]
             [callback (lambda (cb evt)
                         (task:toggle-task-completed (task:task-id task-data))
                         (task-updated-callback))])
        
        ;; 创建文本和日期面板
        (define text-date-panel (new vertical-panel% 
                                     [parent task-item]
                                     [stretchable-width #t]
                                     [alignment '(left top)]
                                     [spacing 2]))
        
        ;; 创建任务文本消息
        (new message% 
             [parent text-date-panel]
             [stretchable-width #t]
             [label (task:task-text task-data)])
        
        ;; 创建截止日期标签
        (when (task:task-due-date task-data)
          (new message% 
               [parent text-date-panel]
               [label (date:format-date-for-display (task:task-due-date task-data))]
               [font (make-font #:size 9 #:family 'modern)]))
        
        ;; 创建编辑按钮
        (new button% 
             [parent task-item]
             [label "✎"]
             [min-width 20]
             [min-height 24]
             [callback (lambda (btn evt)
                         (show-edit-task-dialog task-data task-updated-callback))])
        
        ;; 创建删除按钮
        (new button% 
             [parent task-item]
             [label "×"]
             [min-width 20]
             [min-height 24]
             [callback (lambda (btn evt)
                         (task:delete-task (task:task-id task-data))
                         (task-updated-callback))])))
    
    (void))) 

(provide task-panel%)
