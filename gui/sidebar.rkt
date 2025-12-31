#lang racket/gui

(require (prefix-in core: "../core/list.rkt")
         (prefix-in task: "../core/task.rkt"))

;; 侧边栏类
(define sidebar% 
  (class vertical-panel% 
    (init parent 
          [on-view-change (lambda (view-type [list-id #f] [list-name #f]) (void))]
          [on-task-updated (lambda () (void))])
    
    (super-new [parent parent]
               [min-width 120]
               [spacing 4]
               [border 4]
               [stretchable-width #f])
    
    ;; 回调函数
    (define view-change-callback on-view-change)
    (define task-updated-callback on-task-updated)
    
    ;; 创建搜索面板
    (define search-panel (new vertical-panel% 
                              [parent this]
                              [stretchable-height #f]
                              [spacing 4]
                              [border 4]))
    
    (new message% [parent search-panel] [label "搜索"] [font (make-font #:weight 'bold #:family 'modern #:size 14)])
    
    (new text-field% 
         [parent search-panel]
         [init-value ""]
         [stretchable-width #t]
         [label ""])
    
    ;; 创建智能列表面板
    (define smart-lists-panel (new vertical-panel% 
                                   [parent this]
                                   [stretchable-height #f]
                                   [spacing 4]
                                   [border 4]))
    
    (new message% [parent smart-lists-panel] [label "智能列表"] [font (make-font #:weight 'bold #:family 'modern #:size 14)])
    
    ;; 今天按钮
    (new button% 
         [parent smart-lists-panel]
         [label "今天"]
         [min-width 140]
         [min-height 28]
         [callback (lambda (btn evt)
                     (view-change-callback "today" #f "今天"))])
    
    ;; 计划按钮
    (new button% 
         [parent smart-lists-panel]
         [label "计划"]
         [min-width 140]
         [min-height 28]
         [callback (lambda (btn evt)
                     (view-change-callback "planned" #f "计划"))])
    
    ;; 全部按钮
    (new button% 
         [parent smart-lists-panel]
         [label "全部"]
         [min-width 140]
         [min-height 28]
         [callback (lambda (btn evt)
                     (view-change-callback "all" #f "全部"))])
    
    ;; 完成按钮
    (new button% 
         [parent smart-lists-panel]
         [label "完成"]
         [min-width 140]
         [min-height 28]
         [callback (lambda (btn evt)
                     (view-change-callback "completed" #f "完成"))])
    
    ;; 创建自定义列表面板
    (define my-lists-panel (new vertical-panel% [parent this] [spacing 2]))
    (define list-buttons '())
    
    (new message% [parent my-lists-panel] [label "我的列表"] [font (make-font #:weight 'bold #:family 'modern #:size 14)])
    
    (define lists-container (new vertical-panel% [parent my-lists-panel] [spacing 2]))
    
    ;; 刷新列表按钮
    (define/public (refresh-lists)
      (send lists-container change-children (lambda (children) '()))
      (set! list-buttons '())
      
      (define all-lists (core:get-all-lists))
      (for ([lst all-lists])
        (define list-id (core:todo-list-id lst))
        (define list-name (core:todo-list-name lst))
        
        (define btn (new button% 
                         [parent lists-container]
                         [label list-name]
                         [min-width 140]
                         [min-height 28]
                         [callback (lambda (btn evt) 
                                     (view-change-callback "list" list-id list-name))]))
        
        (set! list-buttons (cons btn list-buttons))))
    
    ;; 创建列表管理面板
    (define list-management-panel (new horizontal-panel% 
                                      [parent this]
                                      [stretchable-height #f]
                                      [spacing 4]))
    
    ;; 添加列表按钮
    (new button% 
         [parent list-management-panel]
         [label "+ 新建列表"]
         [min-width 65]
         [min-height 32]
         [callback (lambda (btn evt)
                     (show-add-list-dialog))])
    
    ;; 删除列表按钮
    (new button% 
         [parent list-management-panel]
         [label "- 删除列表"]
         [min-width 65]
         [min-height 32]
         [callback (lambda (btn evt)
                     ;; TODO: 实现删除列表功能
                     (void))])
    
    ;; 添加列表对话框
    (define (show-add-list-dialog)
      (define dialog (new dialog% 
                         [label "添加新列表"]
                         [parent (send this get-top-level-window)]
                         [width 320]
                         [height 160]))
      
      (define dialog-panel (new vertical-panel% [parent dialog] [spacing 8] [border 12]))
      (new message% [parent dialog-panel] [label "列表名称:"])
      
      (define name-field (new text-field% [parent dialog-panel] [label ""] [init-value ""]))
      
      (define button-panel (new horizontal-panel% [parent dialog-panel] [spacing 8]))
      
      (new button% 
           [parent button-panel]
           [label "确定"]
           [min-width 60]
           [callback (lambda (btn evt)
                       (define name (send name-field get-value))
                       (when (not (equal? name ""))
                         (core:add-list name)
                         (refresh-lists)
                         (task-updated-callback)
                         (send dialog show #f)))])
      
      (new button% 
           [parent button-panel]
           [label "取消"]
           [min-width 60]
           [callback (lambda (btn evt)
                       (send dialog show #f))])
      
      (send name-field focus)
      (send dialog show #t))
    
    (void)))

(provide sidebar%)
