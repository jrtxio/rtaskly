#lang racket/gui

;; Taskly 主应用程序入口文件
;; 负责初始化应用、显示数据库选择对话框和启动主窗口

(require racket
         racket/gui/base
         "src/core/database.rkt"
         "src/gui/main-frame.rkt"
         "src/utils/path.rkt")

;; 全局应用状态
(define app-frame #f)

;; 显示数据文件选择对话框，返回选中的文件路径
(define (show-db-file-dialog)
  (define dialog (new dialog% 
                      [label "选择或创建数据库文件"]
                      [width 500]
                      [height 300]))
  
  ;; 尝试为对话框设置图标
  (define (set-dialog-icon)
    ;; 尝试使用不同尺寸的图标，优先使用适合标题栏的小尺寸图标
    (define icon-paths
      (list (build-path (current-directory) "icons" "16x16.png")
            (build-path (current-directory) "icons" "32x32.png")
            (build-path (current-directory) "icons" "taskly.png")))
    
    ;; 查找第一个存在的图标文件并设置
    (for/first ([icon-path icon-paths] #:when (file-exists? icon-path))
      (send dialog set-icon (make-object bitmap% icon-path))))
  
  (set-dialog-icon)
  
  (define panel (new vertical-panel% [parent dialog] [spacing 10] [border 10]))
  (new message% [parent panel] [label "请选择一个SQLite数据库文件，或输入新文件路径创建。"])
  
  (define file-panel (new horizontal-panel% [parent panel] [spacing 10]))
  (define file-field (new text-field% [parent file-panel] 
                          [label ""] 
                          [init-value (path->string (get-default-db-path))] 
                          [stretchable-width #t]))
  
  ;; 浏览按钮回调函数
  (new button% [parent file-panel] 
       [label "浏览..."] 
       [callback (lambda (btn evt)
                  (define selected-file (get-file "选择数据库文件"))
                  (when selected-file
                    (send file-field set-value (path->string selected-file))))])
  
  (define button-panel (new horizontal-panel% [parent panel] [spacing 10] [alignment '(center center)]))
  
  ;; 确定按钮回调
  (define result #f)
  (new button% [parent button-panel] 
       [label "确定"] 
       [min-width 80]
       [callback (lambda (btn evt)
                  (define file-path (send file-field get-value))
                  (when (non-empty-string? (string-trim file-path))
                    (set! result file-path)
                    (send dialog show #f)))])
  
  (new button% [parent button-panel] 
       [label "取消"] 
       [min-width 80]
       [callback (lambda (btn evt) (send dialog show #f))])
  
  (send dialog show #t)
  result)

;; 运行应用
(define (run-app [db-path #f])
  (when db-path
    (set! app-frame (new main-frame% [db-path db-path]))
    (send app-frame init-app)
    (send app-frame center)
    (send app-frame show #t)))

;; 主程序入口
(define (main)
  ;; 读取上次选择的数据库路径
  (define last-db-path (get-config "last-db-path"))
  
  ;; 如果有上次选择的路径且文件存在，直接使用；否则显示选择对话框
  (define db-path (or (and last-db-path (file-exists? last-db-path) last-db-path)
                      (show-db-file-dialog)))
  
  (run-app db-path))

;; 启动应用
(main)