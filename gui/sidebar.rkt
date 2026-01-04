#lang racket/gui

(require (prefix-in core: "../core/list.rkt")
         (prefix-in task: "../core/task.rkt")
         "language.rkt")

;; 侧边栏类
(define sidebar% 
  (class vertical-panel% 
    (init parent 
          [on-view-change (lambda (view-type [list-id #f] [list-name #f]) (void))]
          [on-task-updated (lambda () (void))])
    
    (super-new [parent parent]
               [min-width 250]
               [spacing 6]
               [border 6]
               [stretchable-width #f])
    
    ;; 回调函数
    (define view-change-callback on-view-change)
    (define task-updated-callback on-task-updated)
    
    ;; 列表按钮列表
    (define list-buttons '())
    
    ;; 当前选中的按钮和原始标签
    (define current-selected-btn #f)
    (define current-selected-original-label #f)
    
    ;; 当前选中列表的ID和名称
    (define current-selected-list-id #f)
    (define current-selected-list-name #f)
    
    ;; 设置选中按钮
    (define/public (set-selected-button btn [list-id #f] [list-name #f])
      ;; 恢复之前选中按钮的原始标签（从当前标签中去除箭头前缀）
      (when current-selected-btn
        (define current-label (send current-selected-btn get-label))
        (when (string-prefix? current-label "→ ")
          (send current-selected-btn set-label (substring current-label 2))))
      ;; 设置当前选中按钮的标签（添加箭头）
      (set! current-selected-btn btn)
      (set! current-selected-list-id list-id)
      (set! current-selected-list-name list-name)
      (when btn
        (define original-label (send btn get-label))
        ;; 如果标签已经包含箭头，先去除
        (when (string-prefix? original-label "→ ")
          (set! original-label (substring original-label 2)))
        (set! current-selected-original-label original-label)
        (send btn set-label (string-append "→ " original-label))))
    
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
                                  [stretchable-width #t]
                                  [alignment '(center center)]))
    
    ;; 今天按钮
    (define today-btn
      (new button% 
           [parent smart-lists-row1]
           [label (translate "今天")]
           [min-width 100]
           [min-height 36]
           [callback (lambda (btn evt) 
                       (set-selected-button btn #f (translate "今天"))
                       (view-change-callback "today" #f (translate "今天")))]))
    
    ;; 计划按钮
    (define planned-btn
      (new button% 
           [parent smart-lists-row1]
           [label (translate "计划")]
           [min-width 100]
           [min-height 36]
           [callback (lambda (btn evt) 
                       (set-selected-button btn #f (translate "计划"))
                       (view-change-callback "planned" #f (translate "计划")))]))
    
    ;; 创建第二行水平面板（All 和 Flagged）
    (define smart-lists-row2 (new horizontal-panel% 
                                  [parent smart-lists-panel]
                                  [stretchable-height #f]
                                  [spacing 4]
                                  [stretchable-width #t]
                                  [alignment '(center center)]))
    
    ;; 全部按钮
    (define all-btn
      (new button% 
           [parent smart-lists-row2]
           [label (translate "全部")]
           [min-width 100]
           [min-height 36]
           [callback (lambda (btn evt) 
                       (set-selected-button btn #f (translate "全部"))
                       (view-change-callback "all" #f (translate "全部")))]))
    
    ;; 已完成按钮
    (define completed-btn
      (new button% 
           [parent smart-lists-row2]
           [label (translate "完成")]
           [min-width 100]
           [min-height 36]
           [callback (lambda (btn evt) 
                       (set-selected-button btn #f (translate "完成"))
                       (view-change-callback "completed" #f (translate "完成")))]))
    
    ;; 创建自定义列表面板
    (define my-lists-panel (new vertical-panel% [parent this] [spacing 2]))
    
    ;; 列表标题
    (define my-lists-label (new message% [parent my-lists-panel] [label (translate "我的列表")] [font (make-font #:weight 'bold #:family 'modern #:size 14)] [stretchable-width #t]))
    
    ;; 列表容器
    (define lists-container (new vertical-panel% [parent my-lists-panel] [spacing 2]))
    
    ;; 列表管理面板（左下角）
    (define list-management-panel (new horizontal-panel% 
                                      [parent my-lists-panel]
                                      [stretchable-height #f]
                                      [spacing 4]
                                      [alignment '(center center)]))
    
    ;; 添加列表按钮
    (define (show-add-list-dialog)
      (define dialog (new dialog% 
                         [label (translate "添加新列表")]
                         [parent (send this get-top-level-window)]
                         [width 320]
                         [height 160]))
      
      (define dialog-panel (new vertical-panel% [parent dialog] [spacing 8] [border 12]))
      (new message% [parent dialog-panel] [label (translate "列表名称:")])
      (define name-field (new text-field% [parent dialog-panel] [label ""] [init-value ""]))
      
      (define button-panel (new horizontal-panel% [parent dialog-panel] [spacing 8]))
      
      (new button% 
           [parent button-panel] 
           [label (translate "确定")]
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
           [label (translate "取消")]
           [min-width 60]
           [callback (lambda (btn evt)
                       (send dialog show #f))])
      
      (send name-field focus)
      (send dialog show #t))
    
    ;; 删除列表按钮
    (define (show-delete-list-dialog)
      ;; 检查是否有选中的自定义列表
      (if (and current-selected-list-id current-selected-list-name)
          ;; 如果有，直接使用当前选中的列表
          (let ([confirm-result (message-box (translate "确认删除") 
                                             (translate "确定要删除列表\"~a\"及其所有任务吗？" current-selected-list-name)
                                             (send this get-top-level-window)
                                             '(yes-no))])
            (when (eq? confirm-result 'yes)
              (core:delete-list current-selected-list-id)
              (refresh-lists)
              (task-updated-callback)))
          ;; 如果没有，提示用户先选中要删除的列表
          (message-box (translate "提示") 
                      (translate "请先选中要删除的列表")
                      (send this get-top-level-window)
                      '(ok))))
    
    ;; 创建添加列表按钮
    (define add-list-btn
      (new button% 
           [parent list-management-panel]
           [label "+"]
           [min-width 40]
           [min-height 32]
           [callback (lambda (btn evt) (show-add-list-dialog))]))
    
    ;; 创建删除列表按钮
    (define delete-list-btn
      (new button% 
           [parent list-management-panel]
           [label "-"]
           [min-width 40]
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
      
      ;; 更新智能列表按钮标签
      (send today-btn set-label (translate "今天"))
      (send planned-btn set-label (translate "计划"))
      (send all-btn set-label (translate "全部"))
      (send completed-btn set-label (translate "完成"))
      
      ;; 更新"我的列表"标题
      (send my-lists-label set-label (translate "我的列表"))
      
      ;; 添加自定义列表按钮
      (define new-buttons '())
      (for ([lst all-lists])
        (define list-id (core:todo-list-id lst))
        (define list-name (core:todo-list-name lst))
        
        (define btn (new button% 
                        [parent lists-container]
                        [label list-name]
                        [min-width 100]
                        [min-height 32]
                        [callback (lambda (btn evt) 
                                    (set-selected-button btn list-id list-name)
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