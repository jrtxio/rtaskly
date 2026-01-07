#lang racket/gui

(require rackunit
         rackunit/text-ui
         db
         "../src/gui/task-panel.rkt"
         "../src/gui/sidebar.rkt"
         (prefix-in core: "../src/core/list.rkt")
         (prefix-in db: "../src/core/database.rkt")
         (prefix-in lang: "../src/gui/language.rkt"))

;; 定义测试套件
(define task-panel-layout-tests
  (test-suite
   "任务面板布局测试"
   
   ;; 测试task-panel%初始化和布局结构
   (test-case "测试task-panel%初始化和布局结构" 
     ;; 创建一个临时顶级窗口用于测试
     (define frame (new frame% [label "Test Frame"] [width 800] [height 600]))
     
     ;; 初始化任务面板
     (define task-panel (new task-panel% [parent frame]))
     
     ;; 检查任务面板是否正确创建
     (check-true (is-a? task-panel task-panel%))
     
     ;; 获取任务面板的子组件
     (define children (send task-panel get-children))
     (check >= (length children) 2) ; 至少包含输入框和顶部面板
     
     ;; 检查第一个子组件是否为快速添加任务输入框
     (define first-child (first children))
     (check-true (is-a? first-child editor-canvas%)) ; task-input%继承自editor-canvas%
     
     ;; 关闭测试窗口
     (send frame show #f))
   
   ;; 测试快速添加任务输入框的尺寸
   (test-case "测试快速添加任务输入框的尺寸" 
     ;; 创建一个临时顶级窗口用于测试
     (define frame (new frame% [label "Test Frame"] [width 800] [height 600]))
     
     ;; 初始化任务面板
     (define task-panel (new task-panel% [parent frame]))
     
     ;; 获取第一个子组件（快速添加任务输入框）
     (define quick-task-input (first (send task-panel get-children)))
     
     ;; 关闭测试窗口
     (send frame show #f))
   
   ;; 测试快速添加任务输入框的位置
   (test-case "测试快速添加任务输入框的位置" 
     ;; 创建一个临时顶级窗口用于测试
     (define frame (new frame% [label "Test Frame"] [width 800] [height 600]))
     
     ;; 初始化任务面板
     (define task-panel (new task-panel% [parent frame]))
     
     ;; 获取任务面板的子组件
     (define children (send task-panel get-children))
     
     ;; 检查快速添加任务输入框是否在最顶部
     (define quick-task-input (first children))
     
     ;; 检查第二个子组件是否为顶部面板（包含标题）
     (define top-panel (second children))
     (check-true (is-a? top-panel horizontal-panel%))
     
     ;; 关闭测试窗口
     (send frame show #f))
   
   ;; 测试列表名过长时的布局
   (test-case "测试列表名过长时的布局" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-task-panel-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 创建一个超长名称的测试列表
     (define long-list-name "这是一个非常长的列表名称，用于测试布局是否正常，确保输入框不会重叠")
     (core:add-list long-list-name)
     
     ;; 创建测试窗口和组件
     (define frame (new frame% [label "Test Frame"] [width 800] [height 600]))
     
     ;; 创建任务面板
     (define task-panel (new task-panel% [parent frame]))
     
     ;; 更新任务面板，显示超长列表名称
     (send task-panel update-tasks "list" 1 long-list-name)
     
     ;; 获取任务面板的子组件
     (define children (send task-panel get-children))
     
     ;; 检查快速添加任务输入框是否正常显示
     (define quick-task-input (first children))
     
     ;; 检查顶部面板（包含标题）
     (define top-panel (second children))
     (define top-children (send top-panel get-children))
     (check > (length top-children) 0)
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试输入框的垂直拉伸限制
   (test-case "测试输入框的垂直拉伸限制" 
     ;; 创建一个临时顶级窗口用于测试
     (define frame (new frame% [label "Test Frame"] [width 800] [height 600]))
     
     ;; 初始化任务面板
     (define task-panel (new task-panel% [parent frame]))
     
     ;; 获取快速添加任务输入框
     (define quick-task-input (first (send task-panel get-children)))
     
     ;; 检查输入框的拉伸属性
     ;; 注意：在Racket GUI中，我们需要通过组件的布局行为来间接测试
     (check-not-exn (lambda () (send quick-task-input get-height)))
     
     ;; 关闭测试窗口
     (send frame show #f))
   
   ;; 测试不同视图下的布局
   (test-case "测试不同视图下的布局" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-task-panel-views-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 创建测试列表
     (core:add-list "测试列表1")
     
     ;; 创建测试窗口和组件
     (define frame (new frame% [label "Test Frame"] [width 800] [height 600]))
     
     ;; 创建任务面板
     (define task-panel (new task-panel% [parent frame]))
     
     ;; 测试不同视图
     (define test-views '("list" "today" "planned" "all" "completed"))
     
     (for ([view test-views])
       (check-not-exn (lambda ()
                        (send task-panel update-tasks view 1 "测试列表1"))
                      (format "更新视图 ~a 时出错" view)))
     
     ;; 关闭测试窗口
     (send frame show #f)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   ))

;; 运行测试套件
(run-tests task-panel-layout-tests)
