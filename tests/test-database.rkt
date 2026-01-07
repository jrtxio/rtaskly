#lang racket

(require rackunit
         rackunit/text-ui
         db
         "../src/core/database.rkt"
         "../src/utils/date.rkt")

;; 定义测试套件
(define database-tests
  (test-suite
   "数据库操作测试"
   
   ;; 测试数据库连接和初始化
   (test-case "测试数据库连接和初始化" 
     ;; 创建唯一的临时数据库文件，使用更精确的时间戳
     (define temp-db-path (format "./tests/temp-test-~a.db" (current-inexact-milliseconds)))
     
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
     
     ;; 验证默认列表是否创建
     (define initial-lists (get-all-lists))
     (check-equal? (length initial-lists) 2)
     
     ;; 关闭连接并清理
     (close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试数据库关闭后的操作
   (test-case "测试数据库关闭后的操作" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./tests/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接并关闭数据库
     (connect-to-database temp-db-path)
     (close-database)
     
     ;; 测试在数据库关闭后调用操作函数，应该不会崩溃
     (check-exn exn:fail? (lambda () (get-all-lists)))
     
     ;; 清理
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试列表相关数据库操作
   (test-case "测试列表相关数据库操作" 
     ;; 创建唯一的临时数据库文件，使用更精确的时间戳
     (define temp-db-path (format "./tests/temp-test-~a.db" (current-inexact-milliseconds)))
     
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
     
     ;; 测试删除不存在的列表（应该不会崩溃）
     (delete-list 9999)
     
     ;; 关闭连接并清理
     (close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试任务相关数据库操作
   (test-case "测试任务相关数据库操作" 
     ;; 创建唯一的临时数据库文件，使用更精确的时间戳
     (define temp-db-path (format "./tests/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (connect-to-database temp-db-path)
     
     ;; 先添加一个列表
     (add-list "测试列表")
     (define list-id (vector-ref (first (get-all-lists)) 0))
     
     ;; 测试添加任务
     (add-task list-id "测试任务1" "2023-01-01" (current-seconds))
     (add-task list-id "测试任务2" #f (current-seconds))
     
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
     
     ;; 测试获取今天的任务
     (define today-tasks (get-today-tasks (get-current-date-string)))
     (check-pred list? today-tasks)
     
     ;; 测试获取计划任务
     (define planned-tasks (get-planned-tasks))
     (check-pred list? planned-tasks)
     
     ;; 测试更新任务
     (update-task task-id list-id "更新后的测试任务" "2023-01-02")
     ;; 通过ID查找更新后的任务，因为任务现在按优先级排序
     (define all-tasks-after-update (get-all-tasks))
     (define updated-task (findf (lambda (t) (= (vector-ref t 0) task-id)) all-tasks-after-update))
     (check-not-false updated-task)
     (check-equal? (vector-ref updated-task 2) "更新后的测试任务")
     
     ;; 测试删除任务
     (delete-task task-id)
     (define final-tasks (get-all-tasks))
     (check-equal? (length final-tasks) 1)
     
     ;; 测试删除不存在的任务（应该不会崩溃）
     (delete-task 9999)
     
     ;; 关闭连接并清理
     (close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试事务处理
   (test-case "测试事务处理" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./tests/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     (connect-to-database temp-db-path)
     (define conn (current-db-connection))
     
     ;; 测试手动事务处理
     (query-exec conn "BEGIN TRANSACTION")
     (add-list "事务测试列表1")
     (add-list "事务测试列表2")
     
     ;; 在事务未提交前，应该能看到新添加的列表
     (define lists-during-transaction (get-all-lists))
     (check-equal? (length lists-during-transaction) 4)
     
     ;; 回滚事务
     (query-exec conn "ROLLBACK")
     
     ;; 事务回滚后，新添加的列表应该消失
     (define lists-after-rollback (get-all-lists))
     (check-equal? (length lists-after-rollback) 2)
     
     ;; 再次测试提交事务
     (query-exec conn "BEGIN TRANSACTION")
     (add-list "事务测试列表3")
     (query-exec conn "COMMIT")
     
     ;; 事务提交后，新添加的列表应该保留
     (define lists-after-commit (get-all-lists))
     (check-equal? (length lists-after-commit) 3)
     
     ;; 关闭连接并清理
     (close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试并发访问
   (test-case "测试并发访问" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./tests/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 第一个连接
     (connect-to-database temp-db-path)
     (add-list "并发测试列表1")
     (define conn1 (current-db-connection))
     
     ;; 第二个连接
     (define conn2 (sqlite3-connect #:database temp-db-path #:mode 'read/write))
     (query-exec conn2 "INSERT INTO list (list_name) VALUES ('并发测试列表2')")
     
     ;; 检查两个连接是否都能看到所有列表
     (define lists1 (get-all-lists))
     (define lists2 (query-rows conn2 "SELECT list_id, list_name FROM list ORDER BY list_id"))
     (check-equal? (length lists1) 4)
     (check-equal? (length lists2) 4)
     
     ;; 关闭连接
     (disconnect conn2)
     (close-database)
     
     ;; 清理
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   ))

;; 运行测试套件
(run-tests database-tests)