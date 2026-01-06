#lang racket/gui

(require "sidebar.rkt"
         "task-panel.rkt"
         "language.rkt"
         "dialogs.rkt"
         "../core/database.rkt"
         "../utils/path.rkt")

;; 主窗口类
(define main-frame% 
  (class frame% 
    (init [db-path #f])
    (super-new [label (translate "Taskly")]
               [min-width 850]
               [min-height 650])
    
    ;; 尝试设置窗口图标
    (define (set-window-icon)
      ;; 尝试使用不同尺寸的图标，优先使用适合标题栏的小尺寸图标
      (define icon-paths
        (list
         (build-path (current-directory) "icons" "16x16.png")
         (build-path (current-directory) "icons" "32x32.png")
         (build-path (current-directory) "icons" "taskly.png")))
      
      (define (try-set-icon paths)
        (when (not (null? paths))
          (define icon-path (car paths))
          (if (file-exists? icon-path)
              (let ([icon-bitmap (make-object bitmap% icon-path)])
                (send this set-icon icon-bitmap))
              (try-set-icon (cdr paths)))))
      
      (try-set-icon icon-paths))
    
    ;; 设置窗口图标
    (set-window-icon)
    
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
    (define file-menu (new menu% [parent menubar] [label (translate "文件")]))
    
    ;; 新建数据库菜单项
    (new menu-item% 
         [parent file-menu] 
         [label (translate "新建数据库")] 
         [shortcut #\n] ; n
         [shortcut-prefix '(ctl)]
         [callback (lambda (menu-item event) 
                     (show-new-database-dialog))])
    
    ;; 打开数据库菜单项
    (new menu-item% 
         [parent file-menu] 
         [label (translate "打开数据库")] 
         [shortcut #\o] ; o
         [shortcut-prefix '(ctl)]
         [callback (lambda (menu-item event) 
                     (show-open-database-dialog))])
    
    ;; 关闭数据库菜单项
    (new menu-item% 
         [parent file-menu] 
         [label (translate "关闭数据库")] 
         [callback (lambda (menu-item event) 
                     (disconnect-database))])
    
    ;; 分隔线
    (new separator-menu-item% [parent file-menu])
    
    ;; 退出菜单项
    (new menu-item% 
         [parent file-menu] 
         [label (translate "退出")] 
         [shortcut #\q] ; q
         [shortcut-prefix '(ctl)]
         [callback (lambda (menu-item event) 
                     (exit))])
    
    ;; 创建设置菜单
    (define settings-menu (new menu% [parent menubar] [label (translate "设置")]))
    
    ;; 创建语言子菜单
    (define language-menu (new menu% [parent settings-menu] [label (translate "语言")]))
    
    ;; 中文菜单项
    (new menu-item% 
         [parent language-menu] 
         [label (translate "中文")] 
         [callback (lambda (menu-item event) 
                     (set-language! "zh")
                     (save-language-setting)
                     (refresh-interface))])
    
    ;; English菜单项
    (new menu-item% 
         [parent language-menu] 
         [label (translate "English")] 
         [callback (lambda (menu-item event) 
                     (set-language! "en")
                     (save-language-setting)
                     (refresh-interface))])
    
    ;; 创建帮助菜单
    (define help-menu (new menu% [parent menubar] [label (translate "帮助")]))
    
    ;; 关于菜单项
    (new menu-item% 
         [parent help-menu] 
         [label (translate "关于")] 
         [callback (lambda (menu-item event) 
                     (show-about-dialog))])
    
    ;; 创建主垂直面板，包含主面板和状态栏
    (define main-vertical-panel (new vertical-panel% 
                                     [parent this] 
                                     [spacing 0] 
                                     [border 0]
                                     [stretchable-width #t]
                                     [stretchable-height #t]))
    
    ;; 创建主面板
    (define main-panel (new horizontal-panel% 
                            [parent main-vertical-panel] 
                            [spacing 0] 
                            [border 0]
                            [stretchable-height #t]))
    
    ;; 创建侧边栏
    (define sidebar (new sidebar% 
                         [parent main-panel]
                         [on-view-change (lambda (view-type [list-id #f] [list-name #f])
                                           (current-view view-type)
                                           (when list-id (current-list-id list-id))
                                           (when list-name (current-list-name list-name))
                                           (current-search-keyword #f)
                                           (send task-panel update-tasks view-type list-id list-name)
                                           (show-status-message (translate "已切换到\"~a\"视图" list-name))
                                           ;; 保存当前选中的列表ID到配置文件
                                           (when (and list-id (equal? view-type "list"))
                                             (set-config "last-selected-list-id" (number->string list-id))))]
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
    
    ;; 创建状态栏
    (define status-bar (new horizontal-panel% 
                           [parent main-vertical-panel]
                           [stretchable-height #f]
                           [stretchable-width #t]
                           [spacing 4]
                           [border 2]
                           [style '(border)]))
    
    ;; 创建状态消息标签
    (define status-message (new message% 
                               [parent status-bar]
                               [label (translate "就绪")]
                               [font (make-font #:size 11 #:family 'modern)]
                               [stretchable-width #t]))
    
    ;; 显示新建数据库对话框
    (define (show-new-database-dialog)
      (define dialog (new dialog% 
                          [label (translate "新建数据库文件")]
                          [parent this]
                          [width 500]
                          [height 300]))
      
      (define panel (new vertical-panel% [parent dialog] [spacing 10] [border 10]))
      
      (new message% [parent panel] [label (translate "请输入新数据库文件的路径和名称。")])
      
      (define file-panel (new horizontal-panel% [parent panel] [spacing 10]))
      
      (define file-field (new text-field% [parent file-panel] 
                              [label ""] 
                              [init-value (path->string (get-default-db-path))] 
                              [stretchable-width #t]))
      
      ;; 浏览按钮回调函数
      (define (browse-callback btn evt)
        (define selected-file (put-file (translate "保存数据库文件")))
        (when selected-file
          ;; 检查并添加.db后缀
          (define final-path (if (equal? #".db" (path-get-extension selected-file))
                                 selected-file
                                 (path-add-extension selected-file #".db")))
          (send file-field set-value (path->string final-path))))
      
      (new button% [parent file-panel] 
           [label (translate "浏览...")] 
           [callback browse-callback])
      
      (define button-panel (new horizontal-panel% [parent panel] [spacing 10] [alignment '(center center)]))
      
      (define (ok-callback)
        (define file-path (send file-field get-value))
        (when (not (equal? (string-trim file-path) ""))
          ;; 检查并添加.db后缀
          (define path (string->path file-path))
          (define final-path (if (equal? #".db" (path-get-extension path))
                                 path
                                 (path-add-extension path #".db")))
          (send dialog show #f)
          (connect-to-db (path->string final-path))))
      
      (new button% [parent button-panel] 
           [label (translate "确定")] 
           [min-width 80]
           [callback (lambda (btn evt) (ok-callback))])
      
      (new button% [parent button-panel] 
           [label (translate "取消")] 
           [min-width 80]
           [callback (lambda (btn evt) (send dialog show #f))])
      
      (send dialog show #t))
    
    ;; 显示打开数据库对话框
    (define (show-open-database-dialog)
      (define selected-file (get-file (translate "选择数据库文件")))
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
      (update-title)
      
      ;; 显示状态消息
      (show-status-message (translate "数据库连接成功")))
    
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
        (update-title)
        
        ;; 显示状态消息
        (show-status-message (translate "数据库已关闭"))))
    
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
                          [label (translate "关于 Taskly")]
                          [parent this]
                          [width 300]
                          [height 200]))
      
      (define panel (new vertical-panel% [parent dialog] [spacing 15] [border 20] [alignment '(center center)]))
      
      (new message% [parent panel] [label (translate "Taskly")] [font (make-font #:weight 'bold #:size 18)])
      (new message% [parent panel] [label "V1.0.0"])
      (new message% [parent panel] [label (translate "极简本地任务管理工具")])
      (new message% [parent panel] [label (translate "完全本地化，用户掌控数据")])
      
      (define button-panel (new horizontal-panel% [parent panel] [spacing 10] [alignment '(center center)]))
      
      (new button% [parent button-panel] 
           [label (translate "确定")] 
           [min-width 80]
           [callback (lambda (btn evt) (send dialog show #f))])
      
      (send dialog show #t))
    
    ;; 刷新界面语言
    (define (refresh-interface)
      ;; 更新窗口标题
      (update-title)
      
      ;; 更新菜单标签
      (send file-menu set-label (translate "文件"))
      (send settings-menu set-label (translate "设置"))
      (send language-menu set-label (translate "语言"))
      (send help-menu set-label (translate "帮助"))
      
      ;; 更新菜单项目
      (for ([item (send file-menu get-items)])
        (when (is-a? item menu-item%)
          (let ([original-label (send item get-label)])
            ;; 根据原始标签更新翻译
            (cond
              [(equal? original-label (translate "新建数据库")) (void)]
              [(equal? original-label (translate "打开数据库")) (void)]
              [(equal? original-label (translate "关闭数据库")) (void)]
              [(equal? original-label (translate "退出")) (void)]
              [(equal? original-label (translate "关于")) (void)]
              [(equal? original-label (translate "中文")) (void)]
              [(equal? original-label (translate "English")) (void)]))))
      
      ;; 更新侧边栏
      (send sidebar refresh-lists)
      (send sidebar set-selected-button (send sidebar get-current-selected-btn))
      
      ;; 更新任务面板
      (send task-panel update-tasks (current-view) (current-list-id) (current-list-name))
      
      ;; 更新状态栏
      (show-status-message (translate "就绪")))
    
    ;; 初始化应用
    (define/public (init-app)
      ;; 加载语言设置
      (load-language-setting)
      
      (when init-db-path
        (connect-to-db init-db-path))
      (send sidebar refresh-lists)
      (send task-panel update-tasks (current-view) (current-list-id) (current-list-name))
      
      ;; 更新窗口标题
      (update-title)
      
      ;; 刷新界面语言
      (refresh-interface))
    
    ;; 暴露一些方法供外部调用
    (define/public (get-current-view) (current-view))
    (define/public (get-current-list-id) (current-list-id))
    (define/public (get-current-list-name) (current-list-name))
    (define/public (get-current-search-keyword) (current-search-keyword))
    (define/public (is-db-connected?) (db-connected?))
    (define/public (show-status-message msg [duration 3000])
      (send status-message set-label msg)
      ;; 3秒后恢复默认状态
      (thread (lambda ()
                (sleep (* duration 0.001))
                ;; 直接更新状态消息，不需要queue-callback
                (send status-message set-label (translate "就绪")))))
    
    (void)))

(provide main-frame%)
