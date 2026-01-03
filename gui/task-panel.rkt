#lang racket/gui

(require "dialogs.rkt"
         (prefix-in task: "../core/task.rkt")
         (prefix-in core: "../core/list.rkt")
         (prefix-in date: "../utils/date.rkt"))

;; 任务面板类
(define task-panel% 
  (class vertical-panel% 
    (init parent [on-task-updated (lambda () (void))])
    
    (super-new [parent parent] [spacing 0] [border 0])
    
    ;; 回调函数
    (define task-updated-callback on-task-updated)
    
    ;; 当前状态
    (define current-view (make-parameter "list"))
    (define current-list-id (make-parameter #f))
    (define current-list-name (make-parameter ""))
    
    ;; 创建顶部水平面板（标题、添加任务按钮）
    (define top-panel (new horizontal-panel% 
                           [parent this]
                           [stretchable-height #f]
                           [spacing 4]
                           [border 4]
                           [stretchable-width #t]))
    
    ;; 创建标题标签
    (define title-label (new message% 
                            [parent top-panel]
                            [label ""][vert-margin 10][font (make-font #:size 18 #:weight 'bold #:family 'modern)][stretchable-width #t]))
    
    ;; 创建右上角功能面板
    (define top-right-panel (new horizontal-panel% 
                                [parent top-panel]
                                [stretchable-height #f]
                                [spacing 4]
                                [stretchable-width #f]))
    
    ;; 添加任务按钮（右上角）
    (define add-task-btn
      (new button% 
           [parent top-right-panel]
           [label "+"][min-width 30][min-height 30][callback (lambda (btn evt) (show-add-task-dialog (current-list-id) (current-list-name) task-updated-callback))]))
    
    ;; 创建任务滚动面板
    (define task-scroll (new panel% [parent this] [style '(vscroll)]))
    
    (define task-list-panel (new vertical-panel% 
                                [parent task-scroll]
                                [min-width 1]
                                [stretchable-height #t]
                                [stretchable-width #t]
                                [spacing 2]))
    
    ;; 显示欢迎信息
    (define (show-welcome-message)
      ;; 清空任务列表
      (send task-list-panel change-children (lambda (children) '()))
      
      ;; 创建欢迎信息面板
      (define welcome-panel (new vertical-panel% 
                            [parent task-list-panel]
                            [alignment '(center center)]
                            [stretchable-height #t]
                            [spacing 16]))
      
      (new message% 
           [parent welcome-panel]
           [label "欢迎使用 Taskly！"]
           [font (make-font #:size 24 #:weight 'bold #:family 'modern)])
      
      (new message% 
           [parent welcome-panel]
           [label "请创建或打开数据库文件以开始使用"]
           [font (make-font #:size 14 #:family 'modern)])
      
      (new message% 
           [parent welcome-panel]
           [label "操作指南："]
           [font (make-font #:size 14 #:weight 'bold #:family 'modern)])
      
      (new message% 
           [parent welcome-panel]
           [label "1. 点击  文件 → 新建数据库  创建新的任务数据库"])
      
      (new message% 
           [parent welcome-panel]
           [label "2. 或点击  文件 → 打开数据库  使用现有数据库"])
      
      ;; 禁用添加任务按钮
      (send add-task-btn enable #f))
    
    ;; 启用界面元素
    (define (enable-interface)
      (send add-task-btn enable #t))
    
    ;; 创建单个任务项
    (define (create-task-item task-data)
      ;; 创建任务项面板
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
      
      ;; 创建优先级标签
      (define priority (task:task-priority task-data))
      (define (priority->color p)
        (case p
          [(0) "#888888"] ; 低优先级 - 灰色
          [(1) "#FFA500"] ; 中优先级 - 橙色
          [(2) "#FF4444"] ; 高优先级 - 红色
          [else "#888888"]))
      
      (define (priority->text p)
        (case p
          [(0) "低"]
          [(1) "中"]
          [(2) "高"]
          [else "低"]))
      
      (new message% 
           [parent task-item]
           [label (string-append "[" (priority->text priority) "]")]
           [font (make-font #:weight 'bold)]
           [color (priority->color priority)]
           [min-width 30]
           [stretchable-width #f])
      
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
        (define due-date-str (task:task-due-date task-data))
        (define today-str (date:get-current-date-string))
        (define diff (date:date-diff due-date-str today-str))
        
        ;; 根据日期差设置不同颜色
        (define date-color
          (cond
            [(date:is-today? due-date-str) "red"]
            [(= diff 1) "orange"]
            [(<= diff 3) "#FFD700"] ; 金色
            [else "black"]))
        
        (new message% 
             [parent text-date-panel]
             [label (date:format-date-for-display due-date-str)]
             [font (make-font #:size 9 #:family 'modern)]
             [color date-color]))
      
      ;; 创建编辑按钮
      (new button% 
           [parent task-item]
           [label "✎"]
           [min-width 20]
           [min-height 24]
           [callback (lambda (btn evt) (show-edit-task-dialog task-data task-updated-callback))])
      
      ;; 创建删除按钮
      (new button% 
           [parent task-item]
           [label "×"]
           [min-width 20]
           [min-height 24]
           [callback (lambda (btn evt)
                       ;; 显示删除确认对话框
                       (define result (message-box "确认删除" 
                                                  (string-append "确定要删除任务\"" 
                                                               (task:task-text task-data) 
                                                               "\"吗？")
                                                  (send btn get-top-level-window)
                                                  '(yes-no)))
                       (when (eq? result 'yes)
                         (task:delete-task (task:task-id task-data))
                         (task-updated-callback)))])
    )
    
    ;; 更新任务列表
    (define/public (update-tasks view-type [list-id #f] [list-name #f] [keyword #f])
      ;; 更新当前状态
      (current-view view-type)
      (when list-id (current-list-id list-id))
      (when list-name (current-list-name list-name))
      
      ;; 更新标题
      (cond
        [(string=? view-type "search")
         (send title-label set-label (if (and keyword (not (equal? keyword "")))
                                         (string-append "搜索结果: \"" keyword "\"")
                                         "搜索结果"))]
        [else
         (send title-label set-label (or list-name ""))])
      
      ;; 清空任务列表
      (send task-list-panel change-children (lambda (children) '()))
      
      ;; 尝试获取任务，处理可能的数据库连接错误
      (define tasks
        (with-handlers ([exn:fail? (lambda (e) #f)])
          (task:get-tasks-by-view view-type list-id keyword)))
      
      (if tasks
          ;; 显示任务列表
          (begin
            (enable-interface)
            ;; 显示任务
            (for ([task-data tasks])
              (create-task-item task-data)))
          ;; 显示欢迎信息
          (show-welcome-message))
    )
    
    (void))
  )

(provide task-panel%)