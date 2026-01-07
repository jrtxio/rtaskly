#lang racket

(require rackunit
         rackunit/text-ui
         db
         "../src/core/task.rkt"
         (prefix-in lst: "../src/core/list.rkt")
         (prefix-in db: "../src/core/database.rkt")
         "../src/utils/date.rkt")

;; 定义测试套件
(define null-date-handling-tests
  (test-suite
   "空日期处理测试"
   
   ;; 测试日期处理函数能正确处理 sql-null 值
   (test-case "测试日期处理函数能正确处理 sql-null 值"
     ;; 使用 sql-null 常量值
     (define null-date sql-null)
     
     ;; 测试 is-today? 函数
     (check-false (is-today? null-date))
     
     ;; 测试 format-date-for-display 函数
     (check-equal? (format-date-for-display null-date) "")
     
     ;; 测试 date-diff 函数
     (check-equal? (date-diff null-date "2023-01-01") 0)
     (check-equal? (date-diff "2023-01-01" null-date) 0))
   
   ;; 测试没有截止日期的任务生命周期
   (test-case "测试没有截止日期的任务生命周期"
     ;; 创建唯一的临时数据库文件，使用更精确的时间戳
     (define temp-db-path (format "./tests/temp-null-date-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (db:add-list "测试列表")
     (define lists (lst:get-all-lists))
     (define test-list (first lists))
     (define test-list-id (lst:todo-list-id test-list))
     
     ;; 测试添加没有截止日期的任务
     (add-task test-list-id "无截止日期任务" #f)
     
     ;; 测试获取任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 1)
     
     ;; 测试任务的截止日期为 #f
     (define task-without-date (first tasks))
     (check-false (task-due-date task-without-date))
     
     ;; 测试编辑没有截止日期的任务
     (edit-task (task-id task-without-date) test-list-id "更新后的无截止日期任务" #f)
     
     ;; 测试删除没有截止日期的任务
     (delete-task (task-id task-without-date))
     (define tasks-after-delete (get-all-tasks))
     (check-equal? (length tasks-after-delete) 0)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试 row->task 函数能正确处理 sql-null 值
   (test-case "测试 row->task 函数能正确处理 sql-null 值"
     ;; 模拟数据库查询结果，其中 due_date 为 sql-null
     (define test-row (vector 1 1 "测试任务" sql-null 0 "1609459200" "extra-column"))
     
     ;; 调用 row->task 函数
     (define result-task (row->task test-row))
     
     ;; 验证结果
     (check-equal? (task-id result-task) 1)
     (check-equal? (task-list-id result-task) 1)
     (check-equal? (task-text result-task) "测试任务")
     (check-false (task-due-date result-task)) ; 应该转换为 #f
     (check-false (task-completed? result-task))
     (check-equal? (task-created-at result-task) 1609459200))
   
   ;; 测试同时处理有截止日期和无截止日期的任务
   (test-case "测试同时处理有截止日期和无截止日期的任务"
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./tests/temp-mixed-dates-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (db:add-list "混合列表")
     (define lists (lst:get-all-lists))
     (define mixed-list (first lists))
     (define mixed-list-id (lst:todo-list-id mixed-list))
     
     ;; 测试添加不同类型的任务
     (add-task mixed-list-id "有截止日期任务" "2023-12-31")
     (add-task mixed-list-id "无截止日期任务1" #f)
     (add-task mixed-list-id "无截止日期任务2" #f)
     
     ;; 测试获取所有任务
     (define mixed-tasks (get-all-tasks))
     (check-equal? (length mixed-tasks) 3)
     
     ;; 测试任务的截止日期类型
     (define tasks-without-date
       (filter (lambda (task) (not (task-due-date task))) mixed-tasks))
     (define tasks-with-date
       (filter task-due-date mixed-tasks))
     
     (check-equal? (length tasks-without-date) 2)
     (check-equal? (length tasks-with-date) 1)
     
     ;; 测试删除所有任务
     (for ([task mixed-tasks])
       (delete-task (task-id task)))
     
     (define tasks-after-delete (get-all-tasks))
     (check-equal? (length tasks-after-delete) 0)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))))  

;; 运行测试
(run-tests null-date-handling-tests)