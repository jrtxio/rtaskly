#lang racket/gui

(require racket/gui/base
         "core/database.rkt"
         "gui/main-frame.rkt"
         "utils/path.rkt")

;; 全局应用状态
(define app-frame #f)

;; 显示数据文件选择对话框
(define (show-db-file-dialog)
  (define dialog (new dialog% 
                      [label "选择或创建数据库文件"]
                      [width 500]
                      [height 300]))
  
  (define panel (new vertical-panel% [parent dialog] [spacing 10] [border 10]))
  
  (new message% [parent panel] [label "请选择一个SQLite数据库文件，或输入新文件路径创建。"])
  
  (define file-panel (new horizontal-panel% [parent panel] [spacing 10]))
  
  (define file-field (new text-field% [parent file-panel] 
                          [label ""] 
                          [init-value (path->string (get-default-db-path))] 
                          [stretchable-width #t]))
  
  ;; 浏览按钮回调函数
  (define (browse-callback btn evt)
    (define selected-file (get-file "选择数据库文件"))
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
      (run-app file-path)))
  
  (new button% [parent button-panel] 
       [label "确定"] 
       [min-width 80]
       [callback (lambda (btn evt) (ok-callback))])
  
  (new button% [parent button-panel] 
       [label "取消"] 
       [min-width 80]
       [callback (lambda (btn evt) (exit))])
  
  (send dialog show #t))

;; 运行应用
(define (run-app [db-path #f])
  ;; 创建主窗口
  (set! app-frame (new main-frame% [db-path db-path]))
  
  ;; 初始化应用
  (send app-frame init-app)
  
  ;; 显示窗口
  (send app-frame center)
  (send app-frame show #t))

;; 主程序入口
(define (main)
  ;; 读取上次选择的数据库路径
  (define last-db-path (get-config "last-db-path"))
  
  ;; 如果有上次选择的路径，直接使用；否则显示选择对话框
  (if (and last-db-path (file-exists? last-db-path))
      (run-app last-db-path)
      (show-db-file-dialog)))

;; 启动应用
(main)