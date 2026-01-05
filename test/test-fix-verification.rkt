#lang racket

(require rackunit
         rackunit/text-ui
         db
         "../core/task.rkt"
         (prefix-in lst: "../core/list.rkt")
         (prefix-in db: "../core/database.rkt")
         "../utils/date.rkt")

;; 定义测试套件
(define fix-verification-tests
  (test-suite
   "修复功能验证测试"
   
   ;; 测试没有截止日期的任务可以正常编辑和删除
   (test-case "没有截止日期的任务可以正常编辑和删除" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-fix-test-~a.db" (current-inexact-milliseconds)))
     
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
     
     (define task (first tasks))
     (define t-id (task-id task))
     
     ;; 测试编辑任务
     (edit-task t-id test-list-id "更新后的无截止日期任务" #f)
     
     ;; 测试编辑后的任务
     (define updated-tasks (get-all-tasks))
     (check-equal? (length updated-tasks) 1)
     
     (define updated-task (first updated-tasks))
     (check-equal? (task-text updated-task) "更新后的无截止日期任务")
     (check-false (task-due-date updated-task))
     
     ;; 测试删除任务
     (delete-task t-id)
     (define tasks-after-delete (get-all-tasks))
     (check-equal? (length tasks-after-delete) 0)
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试多个无截止日期任务的处理
   (test-case "测试多个无截止日期任务的处理" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-multiple-fix-test-~a.db" (current-inexact-milliseconds)))
     
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
     
     ;; 测试添加多个没有截止日期的任务
     (add-task test-list-id "无截止日期任务1" #f)
     (add-task test-list-id "无截止日期任务2" #f)
     (add-task test-list-id "有截止日期任务" "2023-01-01")
     (add-task test-list-id "无截止日期任务3" #f)
     
     ;; 测试获取所有任务
     (define tasks (get-all-tasks))
     (check-equal? (length tasks) 4)
     
     ;; 测试编辑所有无截止日期任务
     (for ([task tasks])
       (when (not (task-due-date task))
         (edit-task (task-id task) test-list-id (string-append (task-text task) "-更新") #f)))
     
     ;; 测试编辑后的任务
     (define updated-tasks (get-all-tasks))
     (check-equal? (length updated-tasks) 4)
     
     ;; 统计更新后的任务
     (define updated-count 0)
     (for ([task updated-tasks])
       (when (string-contains? (task-text task) "-更新")
         (set! updated-count (+ updated-count 1))
         (check-false (task-due-date task))))
     
     (check-equal? updated-count 3) ; 应该有3个无截止日期任务被更新
     
     ;; 测试删除所有无截止日期任务
     (for ([task updated-tasks])
       (when (not (task-due-date task))
         (delete-task (task-id task))))
     
     ;; 测试删除后的任务
     (define tasks-after-delete (get-all-tasks))
     (check-equal? (length tasks-after-delete) 1) ; 应该只剩下1个有截止日期的任务
     
     (define remaining-task (first tasks-after-delete))
     (check-equal? (task-text remaining-task) "有截止日期任务")
     (check-not-false (task-due-date remaining-task))
     
     ;; 关闭数据库连接
     (db:close-database)
     
     ;; 清理临时文件
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试日期处理函数的完整性
   (test-case "测试日期处理函数的完整性" 
     ;; 测试各种日期值的处理
     (define test-cases
       '((sql-null "")
         (#f "")
         ("" "")
         ("2023-01-01" "2023年1月1日")
         ("2023-01-01 12:00" "2023年1月1日 12:00")))
     
     (for ([test-case test-cases])
       (define input (first test-case))
       (define expected (second test-case))
       (check-equal? (format-date-for-display input) expected "format-date-for-display 测试失败"))
     
     ;; 测试 is-today? 函数
     (check-false (is-today? sql-null))
     (check-false (is-today? #f))
     (check-false (is-today? ""))
     
     ;; 测试 date-diff 函数
     (check-equal? (date-diff sql-null "2023-01-01") 0)
     (check-equal? (date-diff "2023-01-01" sql-null) 0)
     (check-equal? (date-diff #f "2023-01-01") 0)
     (check-equal? (date-diff "2023-01-01" #f) 0)
     (check-equal? (date-diff "" "2023-01-01") 0)
     (check-equal? (date-diff "2023-01-01" "") 0))))

;; 运行测试
(run-tests fix-verification-tests)