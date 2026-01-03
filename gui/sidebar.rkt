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
    
    ;; 列表按钮列表
    (define list-buttons '())
    
    ;; 当前选中的按钮和原始标签
    (define current-selected-btn #f)
    (define current-selected-original-label #f)
    
    ;; 设置选中按钮
    (define/public (set-selected-button btn)
      ;; 恢复之前选中按钮的原始标签
      (when current-selected-btn
        (send current-selected-btn set-label current-selected-original-label))
      ;; 设置当前选中按钮的标签（添加箭头）
      (set! current-selected-btn btn)
      (when btn
        (set! current-selected-original-label (send btn get-label))
        (send btn set-label (string-append "→ " current-selected-original-label))))
    
    ;; 创建智能列表面板
    (define smart-lists-panel (new vertical-panel% 
                                   [parent this]
                                   [stretchable-height #f]
                                   [spacing 4]
                                   [border 4]))
    
    ;; 创建第一行水平面板
    (define smart-lists-row1 (new horizontal-panel% 
                                  [parent smart-lists-panel]
                                  [stretchable-height #f]
                                  [spacing 4]
                                  [stretchable-width #t]))
    
    ;; 今天按钮
    (define today-btn
      (new button% 
           [parent smart-lists-row1]
           [label "今天"]
           [min-width 60]
           [min-height 40]
           [callback (lambda (btn evt) 
                       (set-selected-button btn)
                       (view-change-callback "today" #f "今天"))]))
    
    ;; 计划按钮
    (define planned-btn
      (new button% 
           [parent smart-lists-row1]
           [label "计划"]
           [min-width 60]
           [min-height 40]
           [callback (lambda (btn evt) 
                       (set-selected-button btn)
                       (view-change-callback "planned" #f "计划"))]))
    
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
           [label "全部"]
           [min-width 60]
           [min-height 40]
           [callback (lambda (btn evt) 
                       (set-selected-button btn)
                       (view-change-callback "all" #f "全部"))]))
    
    ;; 已完成按钮
    (define completed-btn
      (new button% 
           [parent smart-lists-row2]
           [label "完成"]
           [min-width 60]
           [min-height 40]
           [callback (lambda (btn evt) 
                       (set-selected-button btn)
                       (view-change-callback "completed" #f "完成"))]))
    
    ;; 创建自定义列表面板
    (define my-lists-panel (new vertical-panel% [parent this] [spacing 2]))
    
    ;; 列表标题
    (new message% [parent my-lists-panel] [label "我的列表"] [font (make-font #:weight 'bold #:family 'modern #:size 14)])
    
    ;; 列表容器
    (define lists-container (new vertical-panel% [parent my-lists-panel] [spacing 2]))
    
    ;; 创建列表管理面板（左下角）
    (define list-management-panel (new horizontal-panel% 
                                      [parent my-lists-panel]
                                      [stretchable-height #f]
                                      [spacing 4]))
    
    ;; 添加列表按钮
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
                         (send dialog show #f)))]
           [parent button-panel])
      
      (new button% 
           [parent button-panel]
           [label "取消"]
           [min-width 60]
           [callback (lambda (btn evt)
                       (send dialog show #f))]
           [parent button-panel])
      
      (send name-field focus)
      (send dialog show #t))
    
    ;; 删除列表按钮
    (define (show-delete-list-dialog)
      (define all-lists (core:get-all-lists))
      (when (> (length all-lists) 0)
        ;; 创建删除列表对话框
        (define delete-dialog (new dialog% 
                                  [label "删除列表"]
                                  [width 400]
                                  [height 200]
                                  [stretchable-width #t]
                                  [stretchable-height #f]))
        
        (define delete-panel (new vertical-panel% [parent delete-dialog] [spacing 8] [border 12]))
        (new message% [parent delete-panel] [label "选择要删除的列表:"] [stretchable-width #t])
        
        ;; 创建列表选择下拉框
        (define list-names (map core:todo-list-name all-lists))
        (define list-ids (map core:todo-list-id all-lists))
        
        (define list-choice (new choice% 
                                [parent delete-panel]
                                [label ""]
                                [choices list-names]
                                [selection 0]))
        
        (define delete-button-panel (new horizontal-panel% [parent delete-panel] [spacing 8] [alignment '(center)]))
        
        (new button% 
             [parent delete-button-panel]
             [label "删除"]
             [callback (lambda (btn evt)
                         (define selected-idx (send list-choice get-selection))
                         (define selected-list-id (list-ref list-ids selected-idx))
                         (define selected-list-name (list-ref list-names selected-idx))
                         
                         ;; 显示确认对话框
                         (define confirm-result (message-box "确认删除" 
                                                          (string-append "确定要删除列表\"" 
                                                                      selected-list-name 
                                                                      "\"及其所有任务吗？")
                                                          delete-dialog
                                                          '(yes-no)))
                         
                         (when (eq? confirm-result 'yes)
                           (core:delete-list selected-list-id)
                           (refresh-lists)
                           (task-updated-callback)
                           (send delete-dialog show #f)))]
             [parent delete-button-panel])
        
        (new button% 
             [parent delete-button-panel]
             [label "取消"]
             [callback (lambda (btn evt) (send delete-dialog show #f))]
             [parent delete-button-panel])
        
        (send delete-dialog show #t)))
    
    ;; 创建添加列表按钮
    (define add-list-btn
      (new button% 
           [parent list-management-panel]
           [label "+ 新建列表"]
           [min-width 60]
           [min-height 32]
           [callback (lambda (btn evt) (show-add-list-dialog))]))
    
    ;; 创建删除列表按钮
    (define delete-list-btn
      (new button% 
           [parent list-management-panel]
           [label "- 删除列表"]
           [min-width 60]
           [min-height 32]
           [callback (lambda (btn evt) (show-delete-list-dialog))]))
    
    ;; 刷新列表
    (define/public (refresh-lists)
      ;; 清空自定义列表容器
      (send lists-container change-children (lambda (children) '()))
      
      ;; 尝试获取列表，处理可能的数据库连接错误
      (define all-lists
        (with-handlers ([exn:fail? (lambda (e) '())])
          (core:get-all-lists)))
      
      ;; 根据是否有列表来启用或禁用智能列表按钮
      (define has-lists? (> (length all-lists) 0))
      (send today-btn enable has-lists?)
      (send planned-btn enable has-lists?)
      (send all-btn enable has-lists?)
      (send completed-btn enable has-lists?)
      (send add-list-btn enable has-lists?)
      (send delete-list-btn enable has-lists?)
      
      ;; 添加自定义列表按钮
      (define new-buttons '())
      (for ([lst all-lists])
        (define list-id (core:todo-list-id lst))
        (define list-name (core:todo-list-name lst))
        
        (define btn (new button% 
                        [parent lists-container]
                        [label list-name]
                        [min-width 140]
                        [min-height 28]
                        [callback (lambda (btn evt) 
                                    (set-selected-button btn)
                                    (view-change-callback "list" list-id list-name))]))
        
        (set! new-buttons (cons btn new-buttons)))
      
      ;; 设置列表按钮列表
      (set! list-buttons new-buttons))
    
    ;; 初始状态：禁用所有功能
    (refresh-lists)
    
    ;; 公共方法：获取智能列表按钮
    (define/public (get-smart-list-buttons)
      (list today-btn planned-btn all-btn completed-btn))
    
    ;; 公共方法：获取自定义列表按钮
    (define/public (get-custom-list-buttons)
      ;; 直接从容器中获取子组件，确保返回最新的按钮列表
      (send lists-container get-children))
    
    ;; 公共方法：获取当前选中按钮
    (define/public (get-current-selected-btn)
      current-selected-btn)
    
    ;; 公共方法：获取当前选中按钮的原始标签
    (define/public (get-current-selected-original-label)
      current-selected-original-label)
    
    (void)))

(provide sidebar%)