#lang racket/gui

(require "sidebar.rkt"
         "task-panel.rkt"
         "../core/database.rkt"
         "../utils/path.rkt")

;; 主窗口类
(define main-frame% 
  (class frame% 
    (init [db-path #f])
    (super-new [label "Taskly"]
               [min-width 850]
               [min-height 650])
    
    ;; 保存初始化参数
    (define init-db-path db-path)
    
    ;; 全局状态
    (define current-view (make-parameter "list")) ; "list", "today", "planned", "all", "completed", "search"
    (define current-list-id (make-parameter #f))
    (define current-list-name (make-parameter ""))
    (define current-search-keyword (make-parameter #f))
    (define db-connected? (make-parameter #f))
    (define current-db-path (make-parameter #f))
    
    ;; 创建菜单栏
    (define menubar (new menu-bar% [parent this]))
    
    ;; 创建文件菜单
    (define file-menu (new menu% [parent menubar] [label "文件"]))
    
    ;; 新建数据库菜单项
    (new menu-item% 
         [parent file-menu] 
         [label "新建数据库"] 
         [shortcut #\n] ; n
         [shortcut-prefix '(ctl)]
         [callback (lambda (menu-item event) 
                     (show-new-database-dialog))])
    
    ;; 打开数据库菜单项
    (new menu-item% 
         [parent file-menu] 
         [label "打开数据库"] 
         [shortcut #\o] ; o
         [shortcut-prefix '(ctl)]
         [callback (lambda (menu-item event) 
                     (show-open-database-dialog))])
    
    ;; 关闭数据库菜单项
    (new menu-item% 
         [parent file-menu] 
         [label "关闭数据库"] 
         [callback (lambda (menu-item event) 
                     (disconnect-database))])
    
    ;; 分隔线
    (new separator-menu-item% [parent file-menu])
    
    ;; 退出菜单项
    (new menu-item% 
         [parent file-menu] 
         [label "退出"] 
         [shortcut #\q] ; q
         [shortcut-prefix '(ctl)]
         [callback (lambda (menu-item event) 
                     (exit))])
    
    ;; 创建帮助菜单
    (define help-menu (new menu% [parent menubar] [label "帮助"]))
    
    ;; 关于菜单项
    (new menu-item% 
         [parent help-menu] 
         [label "关于"] 
         [callback (lambda (menu-item event) 
                     (show-about-dialog))])
    
    ;; 创建主面板
    (define main-panel (new horizontal-panel% 
                            [parent this] 
                            [spacing 0] 
                            [border 0]))
    
    ;; 创建侧边栏
    (define sidebar (new sidebar% 
                         [parent main-panel]
                         [on-view-change (lambda (view-type [list-id #f] [list-name #f])
                                           (current-view view-type)
                                           (when list-id (current-list-id list-id))
                                           (when list-name (current-list-name list-name))
                                           (current-search-keyword #f)
                                           (send task-panel update-tasks view-type list-id list-name))]
                         [on-task-updated (lambda ()
                                            (send task-panel update-tasks (current-view) (current-list-id) (current-list-name) (current-search-keyword)))]))
    
    ;; 创建分隔线
    (define divider (new canvas% 
                         [parent main-panel]
                         [min-width 1]
                         [stretchable-width #f]
                         [stretchable-height #t]
                         [paint-callback
                          (lambda (canvas dc)
                            (define-values (w h) (send canvas get-size))
                            (send dc set-pen (make-object color% 209 209 214) 1 'solid)
                            (send dc draw-line 0 0 0 h))]))
    
    ;; 创建任务面板
    (define task-panel (new task-panel% 
                            [parent main-panel]
                            [on-task-updated (lambda ()
                                               (send sidebar refresh-lists)
                                               (send task-panel update-tasks (current-view) (current-list-id) (current-list-name) (current-search-keyword)))]))
    
    ;; 显示新建数据库对话框
    (define (show-new-database-dialog)
      (define dialog (new dialog% 
                          [label "新建数据库文件"]
                          [parent this]
                          [width 500]
                          [height 300]))
      
      (define panel (new vertical-panel% [parent dialog] [spacing 10] [border 10]))
      
      (new message% [parent panel] [label "请输入新数据库文件的路径和名称。"])
      
      (define file-panel (new horizontal-panel% [parent panel] [spacing 10]))
      
      (define file-field (new text-field% [parent file-panel] 
                              [label ""] 
                              [init-value (path->string (get-default-db-path))] 
                              [stretchable-width #t]))
      
      ;; 浏览按钮回调函数
      (define (browse-callback btn evt)
        (define selected-file (put-file "保存数据库文件"))
        (when selected-file
          (send file-field set-value (path->string selected-file))))
      
      (new button% [parent file-panel] 
           [label "浏览..."] 
           [callback browse-callback])
      
      (define button-panel (new horizontal-panel% [parent panel] [spacing 10] [alignment '(center center)]))
      
      (define (ok-callback)
        (define file-path (send file-field get-value))
        (when (not (equal? (string-trim file-path) ""))
          (send dialog show #f)
          (connect-to-db file-path)))
      
      (new button% [parent button-panel] 
           [label "确定"] 
           [min-width 80]
           [callback (lambda (btn evt) (ok-callback))])
      
      (new button% [parent button-panel] 
           [label "取消"] 
           [min-width 80]
           [callback (lambda (btn evt) (send dialog show #f))])
      
      (send dialog show #t))
    
    ;; 显示打开数据库对话框
    (define (show-open-database-dialog)
      (define selected-file (get-file "选择数据库文件"))
      (when selected-file
        (connect-to-db (path->string selected-file))))
    
    ;; 连接到数据库
    (define (connect-to-db db-path)
      ;; 确保目录存在
      (ensure-directory-exists (path-only (string->path db-path)))
      
      ;; 连接到数据库
      (connect-to-database db-path)
      
      ;; 更新状态
      (db-connected? #t)
      (current-db-path db-path)
      
      ;; 保存配置，记录上次选择的数据库路径
      (set-config "last-db-path" db-path)
      
      ;; 更新界面
      (send sidebar refresh-lists)
      (send task-panel update-tasks (current-view) (current-list-id) (current-list-name))
      
      ;; 更新窗口标题
      (update-title))
    
    ;; 关闭数据库
    (define (disconnect-database)
      (when (db-connected?) 
        (close-database)
        (db-connected? #f)
        (current-db-path #f)
        ;; 更新界面
        (send sidebar refresh-lists)
        (send task-panel update-tasks (current-view) (current-list-id) (current-list-name))
        
        ;; 更新窗口标题
        (update-title)))
    
    ;; 更新窗口标题
    (define (update-title)
      (define title
        (if (current-db-path)
            (let* ([db-path (string->path (current-db-path))]
                   [file-name (path->string (file-name-from-path db-path))])
              (format "~a (~a) - Taskly" file-name (current-db-path)))
            "Taskly"))
      (send this set-label title))
    
    ;; 显示关于对话框
    (define (show-about-dialog)
      (define dialog (new dialog% 
                          [label "关于 Taskly"]
                          [parent this]
                          [width 300]
                          [height 200]))
      
      (define panel (new vertical-panel% [parent dialog] [spacing 15] [border 20] [alignment '(center center)]))
      
      (new message% [parent panel] [label "Taskly"] [font (make-font #:weight 'bold #:size 18)])
      (new message% [parent panel] [label "V1.0.0"])
      (new message% [parent panel] [label "极简本地任务管理工具"])
      (new message% [parent panel] [label "完全本地化，用户掌控数据"])
      
      (define button-panel (new horizontal-panel% [parent panel] [spacing 10] [alignment '(center center)]))
      
      (new button% [parent button-panel] 
           [label "确定"] 
           [min-width 80]
           [callback (lambda (btn evt) (send dialog show #f))])
      
      (send dialog show #t))
    
    ;; 初始化应用
    (define/public (init-app)
      (when init-db-path
        (connect-to-db init-db-path))
      (send sidebar refresh-lists)
      (send task-panel update-tasks (current-view) (current-list-id) (current-list-name))
      
      ;; 更新窗口标题
      (update-title))
    
    ;; 暴露一些方法供外部调用
    (define/public (get-current-view) (current-view))
    (define/public (get-current-list-id) (current-list-id))
    (define/public (get-current-list-name) (current-list-name))
    (define/public (get-current-search-keyword) (current-search-keyword))
    (define/public (is-db-connected?) (db-connected?))
    
    (void)))

(provide main-frame%)
