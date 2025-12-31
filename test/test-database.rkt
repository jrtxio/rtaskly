#lang racket

(require rackunit
         rackunit/text-ui
         db
         "../core/database.rkt")

;; 定义测试套件
(define database-tests
  (test-suite
   "数据库操作测试"
   
   ;; 测试数据库连接和初始化
   (test-case "测试数据库连接和初始化" 
     ;; 创建唯一的临时数据库文件，使用更精确的时间戳
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 测试连接和初始化
     (define conn (connect-to-database temp-db-path))
     (check-pred connection? conn)
     
     ;; 验证表是否创建成功
     (define list-tables (query-rows conn "SELECT name FROM sqlite_master WHERE type='table'"))
     (check-true (ormap (lambda (row) (equal? (vector-ref row 0) "list")) list-tables))
     (check-true (ormap (lambda (row) (equal? (vector-ref row 0) "task")) list-tables))
     
     ;; 关闭连接并清理
     (close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试列表相关数据库操作
   (test-case "测试列表相关数据库操作" 
     ;; 创建唯一的临时数据库文件，使用更精确的时间戳
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (connect-to-database temp-db-path)
     
     ;; 测试获取所有列表（默认应该有2个列表）
     (define initial-lists (get-all-lists))
     (check-equal? (length initial-lists) 2)
     
     ;; 测试添加列表
     (add-list "学习")
     (add-list "娱乐")
     
     ;; 测试获取所有列表
     (define lists (get-all-lists))
     (check-equal? (length lists) 4)
     
     ;; 测试更新列表
     (define list-id (vector-ref (first lists) 0))
     (update-list list-id "工作列表")
     (define updated-lists (get-all-lists))
     (check-equal? (vector-ref (first updated-lists) 1) "工作列表")
     
     ;; 测试删除列表
     (delete-list list-id)
     (define remaining-lists (get-all-lists))
     (check-equal? (length remaining-lists) 3)
     
     ;; 关闭连接并清理
     (close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试任务相关数据库操作
   (test-case "测试任务相关数据库操作" 
     ;; 创建唯一的临时数据库文件，使用更精确的时间戳
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (connect-to-database temp-db-path)
     
     ;; 先添加一个列表
     (add-list "测试列表")
     (define list-id (vector-ref (first (get-all-lists)) 0))
     
     ;; 测试添加任务
     (add-task list-id "测试任务1" "2023-01-01" "2023-01-01")
     (add-task list-id "测试任务2" #f "2023-01-01")
     
     ;; 测试获取所有任务
     (define all-tasks (get-all-tasks))
     (check-equal? (length all-tasks) 2)
     
     ;; 测试获取指定列表的任务
     (define list-tasks (get-tasks-by-list list-id))
     (check-equal? (length list-tasks) 2)
     
     ;; 测试获取未完成任务
     (define incomplete-tasks (get-incomplete-tasks))
     (check-equal? (length incomplete-tasks) 2)
     
     ;; 测试切换任务完成状态
     (define task-id (vector-ref (first all-tasks) 0))
     (toggle-task-completed task-id)
     (define after-toggle-tasks (get-incomplete-tasks))
     (check-equal? (length after-toggle-tasks) 1)
     
     ;; 测试获取已完成任务
     (define completed-tasks (get-completed-tasks))
     (check-equal? (length completed-tasks) 1)
     
     ;; 测试更新任务
     (update-task task-id list-id "更新后的测试任务" "2023-01-02")
     (define updated-task (first (get-all-tasks)))
     (check-equal? (vector-ref updated-task 2) "更新后的测试任务")
     
     ;; 测试删除任务
     (delete-task task-id)
     (define final-tasks (get-all-tasks))
     (check-equal? (length final-tasks) 1)
     
     ;; 关闭连接并清理
     (close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   ))

;; 运行测试套件
(run-tests database-tests)