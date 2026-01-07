#lang racket

(require rackunit
         rackunit/text-ui
         db
         "../src/core/task.rkt"
         "../src/core/list.rkt"
         (prefix-in db: "../src/core/database.rkt")
         "../src/utils/date.rkt"
         "../src/utils/path.rkt")

;; 定义测试套件
(define edge-cases-tests
  (test-suite
   "边界情况测试"
   
   ;; 测试任务搜索功能的边界情况
   (test-case "测试任务搜索功能的边界情况" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (db:add-list "工作")
     (db:add-list "生活")
     (define lists (get-all-lists))
     (define work-list-id (todo-list-id (first lists)))
     (define life-list-id (todo-list-id (second lists)))
     
     ;; 添加测试任务
     (add-task work-list-id "项目报告" "2023-01-01")
     (add-task work-list-id "团队会议" #f)
     (add-task life-list-id "购买生活用品" "2023-01-02")
     (add-task work-list-id "编写项目文档" "2023-01-03")
     
     ;; 测试搜索非常长的关键词
     (define long-keyword (make-string 1000 #\a))
     (define search-results1 (search-tasks long-keyword))
     (check-pred list? search-results1)
     (check-equal? (length search-results1) 0) ; 应该找到0个任务
     
     ;; 测试搜索只包含空格的关键词
     (define search-results2 (search-tasks "   "))
     (check-pred list? search-results2)
     
     ;; 测试搜索特殊字符
     (define search-results3 (search-tasks "!@#$%^&*()_+"))
     (check-pred list? search-results3)
     
     ;; 测试搜索数字
     (define search-results4 (search-tasks "2023"))
     (check-pred list? search-results4)
     
     ;; 测试搜索大小写混合
     (define search-results5 (search-tasks "PROJECT"))
     (check-pred list? search-results5)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试任务分组功能的边界情况
   (test-case "测试任务分组功能的边界情况" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (db:add-list "列表1")
     (db:add-list "列表2")
     (db:add-list "列表3")
     (define lists (get-all-lists))
     (define list1-id (todo-list-id (first lists)))
     (define list2-id (todo-list-id (second lists)))
     (define list3-id (todo-list-id (third lists)))
     
     ;; 添加大量任务
     (for ([i (in-range 100)])
       (add-task list1-id (format "列表1-任务~a" i) #f))
     
     (for ([i (in-range 50)])
       (add-task list2-id (format "列表2-任务~a" i) #f))
     
     ;; 列表3不添加任务
     
     ;; 获取所有任务
     (define all-tasks (get-all-tasks))
     (check-equal? (length all-tasks) 150)
     
     ;; 测试分组功能
     (define grouped-tasks (group-tasks-by-list all-tasks))
     (check-pred list? grouped-tasks)
     (check-equal? (length grouped-tasks) 2) ; 应该有2个分组，因为只有列表1和列表2有任务
     
     ;; 检查每个分组是否包含正确的任务数量
     (define total-task-count 0)
     (for ([group grouped-tasks])
       (define list-name (car group))
       (define tasks (cdr group))
       (check-pred list? tasks)
       (set! total-task-count (+ total-task-count (length tasks))))
     
     ;; 检查任务数量总和
     (check-equal? total-task-count 150)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试日期处理的边界情况
   (test-case "测试日期处理的边界情况" 
     ;; 测试日期规范化
     (check-equal? (normalize-date-string "2023-01-01") "2023-01-01") ; 正常日期
     (check-equal? (normalize-date-string "  2023-01-01  ") "2023-01-01") ; 前后有空格
     (check-equal? (normalize-date-string "2023-1-1") "2023-01-01") ; 短格式
     (check-false (normalize-date-string "2023-01-32")) ; 无效日期
     (check-false (normalize-date-string "invalid-date")) ; 无效格式
     (check-false (normalize-date-string "2023/01/01")) ; 错误分隔符
     )
   
   ;; 测试路径处理的边界情况
   (test-case "测试路径处理的边界情况" 
     ;; 测试safe-file-exists?函数
     (check-false (safe-file-exists? "不存在的文件.txt")) ; 不存在的文件
     (check-false (safe-file-exists? "./不存在的目录/文件.txt")) ; 不存在的目录
     
     ;; 测试get-absolute-path函数
     (check-pred string? (get-absolute-path ".")) ; 当前目录
     (check-pred string? (get-absolute-path "..")) ; 父目录
     (check-pred string? (get-absolute-path "./test")) ; 相对路径
     
     ;; 测试get-filename函数
     (check-equal? (get-filename "./test/file.txt") "file.txt")
     (check-equal? (get-filename "/home/user/file.txt") "file.txt")
     (check-equal? (get-filename "file.txt") "file.txt")
     )
   
   ;; 测试任务操作的边界情况
   (test-case "测试任务操作的边界情况" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (db:add-list "测试列表")
     (define list-id (todo-list-id (first (get-all-lists))))
     
     ;; 测试添加空任务文本
     (add-task list-id "" #f)
     (define tasks-after-empty (get-all-tasks))
     (check-equal? (length tasks-after-empty) 1)
     (check-equal? (task-text (first tasks-after-empty)) "")
     
     ;; 测试添加非常长的任务文本
     (define long-text (make-string 10000 #\a))
     (add-task list-id long-text #f)
     (define tasks-after-long (get-all-tasks))
     (check-equal? (length tasks-after-long) 2)
     (check-equal? (string-length (task-text (second tasks-after-long))) 10000)
     
     ;; 测试添加无效日期的任务
     (add-task list-id "无效日期任务" "2023-02-30")
     (define tasks-after-invalid-date (get-all-tasks))
     (check-equal? (length tasks-after-invalid-date) 3)
     (check-true (or (sql-null? (task-due-date (third tasks-after-invalid-date))) (equal? (task-due-date (third tasks-after-invalid-date)) #f) (string? (task-due-date (third tasks-after-invalid-date)))))
     
     ;; 测试切换不存在的任务状态
     (toggle-task-completed 9999) ; 不存在的任务ID
     ;; 应该不会抛出异常
     
     ;; 测试编辑不存在的任务
     (edit-task 9999 list-id "编辑不存在的任务" #f) ; 不存在的任务ID
     ;; 应该不会抛出异常
     
     ;; 测试删除不存在的任务
     (delete-task 9999) ; 不存在的任务ID
     ;; 应该不会抛出异常
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试列表操作的边界情况
   (test-case "测试列表操作的边界情况" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 测试添加空名称列表
     (add-list "")
     (define lists-after-empty (get-all-lists))
     (check-equal? (length lists-after-empty) 3) ; 2个默认列表 + 1个空名称列表
     
     ;; 测试添加非常长的列表名称
     (define long-list-name (make-string 1000 #\a))
     (add-list long-list-name)
     (define lists-after-long (get-all-lists))
     (check-equal? (length lists-after-long) 4)
     
     ;; 测试更新不存在的列表
     (update-list 9999 "更新不存在的列表") ; 不存在的列表ID
     ;; 应该不会抛出异常
     
     ;; 测试删除不存在的列表
     (delete-list 9999) ; 不存在的列表ID
     ;; 应该不会抛出异常
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试数据库操作的边界情况
   (test-case "测试数据库操作的边界情况" 
     ;; 测试连接到不存在的目录
     (define invalid-db-path "./test/不存在的目录/temp.db")
     (check-exn exn:fail? (lambda () (db:connect-to-database invalid-db-path))) ; 应该抛出异常
     
     ;; 测试关闭未连接的数据库
     (db:close-database) ; 应该不会抛出异常
     )
   
   ;; 测试任务视图功能的边界情况
   (test-case "测试任务视图功能的边界情况" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (db:add-list "测试列表")
     (define list-id (todo-list-id (first (get-all-lists))))
     
     ;; 测试获取空的任务视图
     (define empty-today-view (get-tasks-by-view "today"))
     (check-pred list? empty-today-view)
     (check-equal? (length empty-today-view) 0)
     
     (define empty-planned-view (get-tasks-by-view "planned"))
     (check-pred list? empty-planned-view)
     (check-equal? (length empty-planned-view) 0)
     
     (define empty-completed-view (get-tasks-by-view "completed"))
     (check-pred list? empty-completed-view)
     (check-equal? (length empty-completed-view) 0)
     
     ;; 测试无效视图类型
     (define invalid-view (get-tasks-by-view "invalid-view-type"))
     (check-pred list? invalid-view)
     (check-equal? (length invalid-view) 0)
     
     ;; 测试列表视图的边界情况
     (define invalid-list-view (get-tasks-by-view "list" 9999)) ; 不存在的列表ID
     (check-pred list? invalid-list-view)
     ;; 应该不会抛出异常
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   ))

;; 运行测试套件
(run-tests edge-cases-tests)