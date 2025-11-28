#lang racket/gui

;; =============================================================================
;; 1. 数据结构与状态 (Data & State)
;; =============================================================================

;; 任务结构体
(struct task (title date completed? list-category) #:mutable #:transparent)

;; 状态变量
(define current-category "工作")
(define my-lists (list "工作" "生活" "副业" "理财")) 

;; 初始数据
(define all-tasks
  (list
   (task "写一本 Racket 书籍" "2025-04-02" #f "工作")
   (task "写一个 SOME/IP 协议栈客户端" "2025-03-28" #f "工作")
   (task "买 3D 打印机" "2025-08-12" #f "生活")
   (task "给猫买猫粮" "今天" #t "生活")))

;; =============================================================================
;; 2. 弹窗组件 (Dialogs)
;; =============================================================================

;; 添加列表弹窗
(define (show-add-list-dialog parent-frame success-callback)
  (define dlg (new dialog% [label "添加新列表"] [parent parent-frame] [width 300]))
  (define input (new text-field% [label "列表名称"] [parent dlg]))
  (define btn-panel (new horizontal-panel% [parent dlg] [alignment '(center center)]))
  
  (new button% [parent btn-panel] [label "确定"]
       [callback (lambda (b e)
                   (success-callback (send input get-value))
                   (send dlg show #f))])
  (new button% [parent btn-panel] [label "取消"]
       [callback (lambda (b e) (send dlg show #f))])
  (send dlg show #t))

;; 添加任务弹窗
(define (show-add-task-dialog parent-frame success-callback)
  (define dlg (new dialog% [label "添加新任务"] [parent parent-frame] [width 400]))
  (define desc-input (new text-field% [label "任务描述:"] [parent dlg]))
  
  (define date-panel (new horizontal-panel% [parent dlg]))
  (new check-box% [label "截止日期: "][parent date-panel])
  (define date-input (new text-field% [label #f] [parent date-panel] [init-value "2025-xx-xx"]))
  
  (define btn-panel (new horizontal-panel% [parent dlg] [alignment '(center center)]))
  (new button% [parent btn-panel] [label "确定"]
       [callback (lambda (b e)
                   (success-callback (send desc-input get-value) (send date-input get-value))
                   (send dlg show #f))])
  (new button% [parent btn-panel] [label "取消"]
       [callback (lambda (b e) (send dlg show #f))])
  (send dlg show #t))

;; =============================================================================
;; 3. 主界面逻辑 (Main Window)
;; =============================================================================

(define (show-main-window)
  (define frame (new frame% [label "RReminder"] [width 800] [height 550]))
  (define main-panel (new horizontal-panel% [parent frame] [spacing 0]))

  ;; -------------------------------------------------------
  ;; 左侧边栏 (Sidebar)
  ;; -------------------------------------------------------
  (define sidebar (new vertical-panel% [parent main-panel] 
                       [style '(border)] 
                       [stretchable-width #f] [min-width 200] 
                       [spacing 5] [horiz-margin 10] [vert-margin 10]))

  ;; 1. 搜索
  (new button% [parent sidebar] [label "🔍 搜索"] [stretchable-width #t]
       [callback (lambda (b e) (message-box "提示" "搜索功能开发中..." frame))])

  ;; 2. 过滤器
  (define filter-pane (new pane% [parent sidebar] [stretchable-height #f])) 
  (define fp-row1 (new horizontal-panel% [parent filter-pane] [spacing 5]))
  (new button% [parent fp-row1] [label "今天"] [stretchable-width #t])
  (new button% [parent fp-row1] [label "计划"] [stretchable-width #t])
  
  (define fp-row2 (new horizontal-panel% [parent filter-pane] [spacing 5]))
  (new button% [parent fp-row2] [label "全部"] [stretchable-width #t])
  (new button% [parent fp-row2] [label "完成"] [stretchable-width #t])

  (new horizontal-panel% [parent sidebar] [min-height 10] [stretchable-height #f]) ; Spacer

  ;; 3. "我的列表" 标题
  (new message% [parent sidebar] [label "我的列表"] 
       [font (make-font #:size 10 #:weight 'bold #:family 'default)] [stretchable-width #t])

  ;; 4. 动态列表区域 (容器)
  (define list-box-panel (new vertical-panel% [parent sidebar] [style '(auto-vscroll)]))

  ;; -------------------------------------------------------
  ;; 右侧内容区 (Content)
  ;; -------------------------------------------------------
  (define content (new vertical-panel% [parent main-panel] 
                       [style '(border)]
                       [horiz-margin 10] [vert-margin 10] [spacing 5]))

  (define header-msg (new message% [parent content] [label current-category] 
                          [font (make-font #:size 18 #:weight 'bold)] [auto-resize #t]))

  (define task-scroll-panel (new vertical-panel% [parent content] [style '(auto-vscroll)] [spacing 5]))

  ;; -------------------------------------------------------
  ;; 核心逻辑函数 (Refresher functions)
  ;; -------------------------------------------------------
  
  ;; 刷新右侧任务列表
  (define (refresh-task-area)
    (send header-msg set-label current-category)
    (send task-scroll-panel change-children (lambda (c) '())) ; 清空旧控件
    
    ;; 筛选当前分类下的任务
    (define visible-tasks 
      (filter (lambda (t) (string=? (task-list-category t) current-category)) all-tasks))
    
    (for ([t visible-tasks])
      (define row (new horizontal-panel% [parent task-scroll-panel] 
                       [stretchable-height #f] [min-height 35] 
                       [style '(border)] [alignment '(left center)]))
      
      ;; 复选框:点击更新数据状态
      (new check-box% [parent row] [label (task-title t)] 
           [value (task-completed? t)]
           [horiz-margin 10]
           [callback (lambda (c e) 
                       (set-task-completed?! t (send c get-value)))])
      
      (new horizontal-panel% [parent row]) ; Spacer
      
      (unless (string=? (task-date t) "")
        (new message% [parent row] [label (task-date t)] 
             [font (make-font #:size 9 #:style 'italic)] [horiz-margin 10]))))

  ;; 刷新左侧列表按钮
  (define (refresh-sidebar-lists)
    (send list-box-panel change-children (lambda (c) '())) ; 清空
    (for ([lname my-lists])
      (new button% [parent list-box-panel] [label lname] 
           [stretchable-width #t] [horiz-margin 2]
           [callback (lambda (b e)
                       (set! current-category lname) ; 更新状态
                       (refresh-task-area))]))      ; 刷新界面
    
    ;; 添加列表按钮 (总是放在最后)
    (new vertical-panel% [parent sidebar]) ; Spring
    (new button% [parent sidebar] [label "+ 添加列表"] 
         [stretchable-width #t] [stretchable-height #f]
         [callback (lambda (b e)
                     (show-add-list-dialog frame 
                                           (lambda (new-name)
                                             (set! my-lists (append my-lists (list new-name)))
                                             (refresh-sidebar-lists))))]))

  ;; 底部 "+ 新增事项" 按钮
  (new button% [parent content] [label "+ 新增事项"] 
       [stretchable-width #t] [stretchable-height #f]
       [callback (lambda (b e)
                   (show-add-task-dialog frame 
                                         (lambda (title date)
                                           ;; 添加新任务到数据列表
                                           (set! all-tasks (append all-tasks (list (task title date #f current-category))))
                                           (refresh-task-area))))])

  ;; 初始化
  (refresh-sidebar-lists)
  (refresh-task-area)
  (send frame show #t))

;; =============================================================================
;; 4. Welcome 界面 (入口)
;; =============================================================================

(define (show-welcome-window)
  (define frame (new frame% [label "Welcome to RReminder"] [width 400] [height 300]))
  
  (define panel (new vertical-panel% [parent frame] [alignment '(center center)] [spacing 15]))

  (new message% [parent panel] [label "📄"] [font (make-font #:size 40)]) 
  (new message% [parent panel] [label "Welcome to RReminder"] [font (make-font #:size 16 #:weight 'bold)])
  (new message% [parent panel] [label "version 0.9"])

  (new button% [parent panel] [label "新建仓库"] [min-width 120]
       [callback (lambda (btn event)
                   (send frame show #f)
                   (show-main-window))])

  (define bottom-pane (new horizontal-panel% [parent panel] 
                           [alignment '(center bottom)] [stretchable-height #t]))
  (new button% [parent bottom-pane] [label "文档"])
  (new button% [parent bottom-pane] [label "支持"])

  (send frame center)
  (send frame show #t))

;; 启动
(show-welcome-window)