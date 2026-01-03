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
    
    ;; 创建智能列表面板
    (define smart-lists-panel (new vertical-panel% 
                                   [parent this]
                                   [stretchable-height #f]
                                   [spacing 4]
                                   [border 4]))
    
    ;; 创建第一行水平面板（Today 和 Scheduled）
    (define smart-lists-row1 (new horizontal-panel% 
                                  [parent smart-lists-panel]
                                  [stretchable-height #f]
                                  [spacing 4]
                                  [stretchable-width #t]))
    
    ;; 今天按钮
    (define today-btn
      (new button% 
           [parent smart-lists-row1]
           [label "今天"][min-width 60][min-height 40][callback (lambda (btn evt)(view-change-callback "today" #f "今天"))]))
    
    ;; 计划按钮
    (define planned-btn
      (new button% 
           [parent smart-lists-row1]
           [label "计划"][min-width 60][min-height 40][callback (lambda (btn evt)(view-change-callback "planned" #f "计划"))]))
    
    ;; 创建第二行水平面板（All 和 Flagged）
    (define smart-lists-row2 (new horizontal-panel% 
                                  [parent smart-lists-panel]
                                  [stretchable-height #f]
                                  [spacing 4]
                                  [stretchable-width #t]))
    
    ;; 全部按钮
    (define all-btn
      (new button% 
           [parent smart-lists-row2]
           [label "全部"][min-width 60][min-height 40][callback (lambda (btn evt)(view-change-callback "all" #f "全部"))]))
    
    ;; 已完成按钮
    (define completed-btn
      (new button% 
           [parent smart-lists-row2]
           [label "完成"][min-width 60][min-height 40][callback (lambda (btn evt)(view-change-callback "completed" #f "完成"))]))
    
    ;; 创建自定义列表面板
    (define my-lists-panel (new vertical-panel% [parent this] [spacing 2]))
    
    ;; 列表按钮列表
    (define list-buttons '())
    
    (new message% [parent my-lists-panel] [label "我的列表"] [font (make-font #:weight 'bold #:family 'modern #:size 14)])
    
    (define lists-container (new vertical-panel% [parent my-lists-panel] [spacing 2]))
    
    ;; 创建列表管理面板（左下角）
    (define list-management-panel (new horizontal-panel% 
                                      [parent my-lists-panel]
                                      [stretchable-height #f]
                                      [spacing 4]))
    
    ;; 添加列表按钮
    (define add-list-btn
      (new button% 
           [parent list-management-panel]
           [label "+ 新建列表"][min-width 65][min-height 32][callback (lambda (btn evt)(show-add-list-dialog))]))
    
    ;; 删除列表按钮
    (define delete-list-btn
      (new button% 
           [parent list-management-panel]
           [label "- 删除列表"][min-width 65][min-height 32][callback (lambda (btn evt)
                                                                       ;; TODO: 实现删除列表功能
                                                                       (void))]))
    
    ;; 刷新列表按钮
    (define/public (refresh-lists)
      (send lists-container change-children (lambda (children) '()))
      (set! list-buttons '())
      
      ;; 尝试获取列表，处理可能的数据库连接错误
      (define all-lists
        (with-handlers ([exn:fail? (lambda (e) '())])
          (core:get-all-lists)))
      
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
        
        (set! list-buttons (cons btn list-buttons)))
      
      ;; 根据是否有列表来启用或禁用智能列表按钮
      (define has-lists? (> (length all-lists) 0))
      (send today-btn enable has-lists?)
      (send planned-btn enable has-lists?)
      (send all-btn enable has-lists?)
      (send completed-btn enable has-lists?)
      (send add-list-btn enable has-lists?)
      (send delete-list-btn enable has-lists?))
    
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
    
    ;; 初始状态：禁用所有功能
    (refresh-lists)
    
    (void)))

(provide sidebar%)
