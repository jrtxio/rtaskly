#lang racket/gui

;; 任务面板模块，定义任务输入控件和任务列表显示
;; 包含自定义任务输入控件和任务面板类

(require "dialogs.rkt"
         (prefix-in task: "../core/task.rkt")
         (prefix-in core: "../core/list.rkt")
         (prefix-in date: "../utils/date.rkt")
         "language.rkt")

(provide parse-task-input
         task-panel%
         task-input%)

;; 自定义任务输入控件，支持占位符和回车键提交
(define task-input%
  (class editor-canvas%
    (init-field [placeholder ""] [callback (λ (t) (void))])
    
    ;; 禁止滚动条
    (super-new [style '(no-hscroll no-vscroll)])
    
    ;; 监听文本变化来隐藏占位符
    (define showing-placeholder? #t)
    
    ;; 设置字体
    (define font (send the-font-list find-or-create-font 13 'default 'normal 'normal))
    
    (define text (new text%))
    (send this set-editor text)
    
    ;; 关键:让编辑器可编辑
    (send text lock #f)
    
    ;; 设置字体样式
    (define style-delta (new style-delta%))
    (send style-delta set-delta 'change-size 13)
    (send text change-style style-delta)
    
    ;; 处理回车键提交
    (define/override (on-char event)
      (cond
        [(equal? (send event get-key-code) #\return)
         (define content (send text get-text))
         ;; 只有非空内容才处理
         (unless (string=? (string-trim content) "")
           (callback content)
           (send text erase)
           (set! showing-placeholder? #t)
           (send this refresh))]
        [else
         (super on-char event)
         (set! showing-placeholder? (= (send text last-position) 0))
         (send this refresh)]))
    
    (define/override (on-paint)
      (super on-paint)
      (define dc (send this get-dc))
      (define-values (w h) (send this get-client-size))
      
      (define has-focus? (send this has-focus?))
      
      ;; 绘制方正边框
      (if has-focus? 
          (send dc set-pen (make-object color% 0 120 255) 2 'solid) 
          (send dc set-pen (make-object color% 200 200 200) 1 'solid))
      
      (send dc set-brush "white" 'transparent)
      (send dc draw-rectangle 0 0 w h)
      
      ;; 绘制占位符，垂直居中
      (when (and showing-placeholder? (not has-focus?))
        (send dc set-text-foreground (make-object color% 160 160 160))
        (send dc set-font font)
        ;; 计算文字的垂直居中位置
        (define-values (text-width text-height ascent descent) 
          (send dc get-text-extent placeholder font))
        (define text-y (quotient (- h text-height) 2))
        (send dc draw-text placeholder 10 text-y)))
    
    (define/override (on-focus on?)
      (super on-focus on?)
      (send this refresh))
    
    ;; 提供清除输入的方法
    (define/public (clear-input)
      (send text erase)
      (set! showing-placeholder? #t)
      (send this refresh))
    
    ;; 提供获取内容的方法
    (define/public (get-content)
      (send text get-text))))

;; 解析任务输入，提取任务描述和截止日期
(define (parse-task-input input-str)
  (let ([trimmed (string-trim input-str)])
    ;; 查找时间修饰符的位置
    (define modifier-match
      (or (regexp-match-positions #rx" [+@][0-9]+" trimmed)
          (regexp-match-positions #rx"[+@][0-9]+" trimmed)))
    
    (if modifier-match
        ;; 有时间修饰符
        (let* ([modifier-start (caar modifier-match)]
               [task-text (string-trim (substring trimmed 0 modifier-start))]
               [modifier (string-trim (substring trimmed modifier-start))]
               [parsed-date (date:parse-date-string modifier)])
          (values task-text parsed-date))
        ;; 没有时间修饰符
        (values trimmed #f))))

;; 创建任务面板类
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
    
    ;; 处理快速添加任务
    (define (handle-quick-add-task input-str)
      (define-values (task-text due-date) (parse-task-input input-str))
      (when (not (string=? (string-trim task-text) ""))
        ;; 获取当前选中的列表ID或默认列表
        (define list-id (or (current-list-id)
                          (let ([default-list (core:get-default-list)])
                            (if default-list
                                (core:todo-list-id default-list)
                                (let ([all-lists (core:get-all-lists)])
                                  (if (not (empty? all-lists))
                                      (core:todo-list-id (first all-lists))
                                      #f))))))
        
        (when list-id
          ;; 添加任务
          (task:add-task list-id task-text due-date)
          ;; 调用回调更新界面
          (task-updated-callback))))
    
    ;; 快速添加任务输入框 - 放在最顶部
    (define quick-task-input
      (new task-input%
           [parent this] ;; 直接作为task-panel的子组件
           [min-width 300] ;; 增加最小宽度
           [min-height 30] ;; 固定最小高度
           [stretchable-width #t] ;; 全宽显示
           [stretchable-height #f] ;; 禁止垂直拉伸
           [placeholder (translate "添加任务...")]
           [callback (lambda (content)
                       (handle-quick-add-task content))]))
    
    ;; 创建顶部水平面板（仅包含标题）
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
    
    ;; 创建任务滚动面板
    (define task-scroll (new panel% [parent this] [style '(vscroll)] [stretchable-width #t]))
    
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
           [label (translate "欢迎使用 Taskly！")]
           [font (make-font #:size 24 #:weight 'bold #:family 'modern)])
      (new message%
           [parent welcome-panel]
           [label (translate "请创建或打开数据库文件以开始使用")]
           [font (make-font #:size 14 #:family 'modern)])
      (new message%
           [parent welcome-panel]
           [label (translate "操作指南：")]
           [font (make-font #:size 14 #:weight 'bold #:family 'modern)])
      (new message%
           [parent welcome-panel]
           [label (translate "1. 点击  文件 → 新建数据库  创建新的任务数据库")])
      (new message%
           [parent welcome-panel]
           [label (translate "2. 或点击  文件 → 打开数据库  使用现有数据库")])
      
      ;; 禁用任务输入框
      (send quick-task-input enable #f))
    
    ;; 启用界面元素
    (define (enable-interface)
      (send quick-task-input enable #t))
    
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
      
      ;; 创建文本和日期面板
      (define text-date-panel (new vertical-panel%
                             [parent task-item]
                             [stretchable-width #t]
                             [alignment '(left top)]
                             [spacing 2]))
      
      ;; 创建任务文本标签，使用 message% 组件支持自动换行
      (new message% 
           [parent text-date-panel]
           [label (task:task-text task-data)]
           [stretchable-width #t]
           [stretchable-height #f]
           [min-height 20]
           [horiz-margin 0]
           [vert-margin 0])
      
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
      
      ;; 创建编辑按钮（使用设置图标）
      (new button%
           [parent task-item]
           [label "⚙"]
           [min-width 20]
           [min-height 20]
           [callback (lambda (btn evt) (show-edit-task-dialog task-data task-updated-callback))])
      
      ;; 删除按钮已移至编辑对话框中
      ;; (new button%
      ;;      [parent task-item]
      ;;      [label "×"]
      ;;      [min-width 20]
      ;;      [min-height 24]
      ;;      [callback (lambda (btn evt)
      ;;                  ;; 显示删除确认对话框
      ;;                  (define result (message-box (translate "确认删除")
      ;;                                             (translate "确定要删除任务\"~a\"吗？" 
      ;;                                                          (task:task-text task-data))
      ;;                                             (send btn get-top-level-window)
      ;;                                             '(yes-no)))
      ;;                  (when (eq? result 'yes)
      ;;                    (task:delete-task (task:task-id task-data))
      ;;                    (task-updated-callback))])
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
                                         (translate "搜索结果: \"~a\"" keyword)
                                         (translate "搜索结果")))]
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
    
    (void)))