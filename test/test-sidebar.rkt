#lang racket/gui

(require rackunit
         rackunit/text-ui
         db
         "../gui/sidebar.rkt"
         (prefix-in core: "../core/list.rkt")
         (prefix-in db: "../core/database.rkt"))

;; 定义测试套件
(define sidebar-tests
  (test-suite
   "侧边栏组件测试"
   
   ;; 测试sidebar%初始化
   (test-case "测试sidebar%初始化" 
     ;; 创建一个临时顶级窗口用于测试
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 初始化侧边栏
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 检查侧边栏是否正确创建
     (check-true (is-a? sidebar sidebar%))
     
     ;; 侧边栏是一个容器组件，没有enable?方法，检查其基本结构
     
     ;; 关闭测试窗口
     (send frame show #f))
   
   ;; 测试列表刷新功能
   (test-case "测试列表刷新功能" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-sidebar-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 创建测试列表
     (core:add-list "测试列表1")
     (core:add-list "测试列表2")
     
     ;; 创建测试窗口和侧边栏
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 刷新列表
     (send sidebar refresh-lists)
     
     ;; 检查智能列表按钮是否启用
     ;; 因为已经连接数据库并创建了列表，所以应该启用
     ;; 注意：这里我们无法直接访问内部按钮，所以测试侧边栏的基本功能
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试回调函数功能
   (test-case "测试回调函数功能" 
     ;; 创建测试窗口
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 用于跟踪回调调用的变量
     (define callback-called #f)
     (define callback-view-type #f)
     (define callback-list-id #f)
     (define callback-list-name #f)
     
     ;; 定义测试回调函数
     (define (test-view-change-callback view-type [list-id #f] [list-name #f])
       (set! callback-called #t)
       (set! callback-view-type view-type)
       (set! callback-list-id list-id)
       (set! callback-list-name list-name))
     
     ;; 创建侧边栏，传递测试回调
     (define sidebar (new sidebar% [parent frame] [on-view-change test-view-change-callback]))
     
     ;; 刷新列表（初始化）
     (send sidebar refresh-lists)
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 检查回调是否正确注册
     (check-false callback-called) ;; 初始状态下回调不应被调用
     )
   
   ;; 测试列表管理功能的间接测试
   (test-case "测试列表管理功能" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-sidebar-lists-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 创建测试窗口
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 创建侧边栏
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 初始列表数量
     (define initial-lists (core:get-all-lists))
     (define initial-count (length initial-lists))
     
     ;; 添加一个新列表
     (core:add-list "新测试列表")
     
     ;; 刷新侧边栏列表
     (send sidebar refresh-lists)
     
     ;; 检查列表数量是否增加
     (define after-add-lists (core:get-all-lists))
     (check-equal? (length after-add-lists) (+ initial-count 1))
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试错误处理
   (test-case "测试错误处理" 
     ;; 确保数据库连接已关闭
     (db:close-database)
     
     ;; 创建测试窗口
     (define frame (new frame% [label "Test Frame"] [width 300] [height 400]))
     
     ;; 创建侧边栏
     (define sidebar (new sidebar% [parent frame]))
     
     ;; 尝试刷新列表，应该能处理数据库连接错误
     ;; 这个测试主要验证组件不会崩溃
     (send sidebar refresh-lists)
     
     ;; 关闭测试窗口
     (send frame show #f)
     )
   ))

;; 运行测试套件
(run-tests sidebar-tests)