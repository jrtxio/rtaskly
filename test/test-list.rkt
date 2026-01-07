#lang racket

(require rackunit
         rackunit/text-ui
         db
         "../src/core/list.rkt"
         (prefix-in db: "../src/core/database.rkt"))

;; 定义测试套件
(define list-tests
  (test-suite
   "列表管理测试"
   
   ;; 测试列表管理功能
   (test-case "测试列表管理功能" 
     ;; 创建唯一的临时数据库文件，使用更精确的时间戳
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 测试获取所有列表（默认应该有2个列表）
     (define initial-lists (get-all-lists))
     (check-pred list? initial-lists)
     (check-equal? (length initial-lists) 2)
     
     ;; 测试添加列表
     (db:add-list "学习")
     (db:add-list "娱乐")
     (db:add-list "健康")
     
     (define lists-after-add (get-all-lists))
     (check-equal? (length lists-after-add) 5)
     
     ;; 测试获取列表名称
     (define first-list (first lists-after-add))
     (check-equal? (todo-list-name first-list) "工作")
     
     ;; 测试根据ID获取列表
     (define list-id (todo-list-id first-list))
     (define found-list (get-list-by-id list-id))
     (check-equal? found-list first-list)
     
     ;; 测试获取不存在的列表
     (define not-found-list (get-list-by-id 9999))
     (check-false not-found-list)
     
     ;; 测试更新列表
     (db:update-list list-id "工作列表")
     (define updated-list (get-list-by-id list-id))
     (check-equal? (todo-list-name updated-list) "工作列表")
     
     ;; 测试更新不存在的列表
     (db:update-list 9999 "不存在的列表")
     
     ;; 测试获取默认列表
     (define default-list (get-default-list))
     (check-pred todo-list? default-list)
     (check-equal? (todo-list-name default-list) "工作列表")
     
     ;; 测试删除列表
     (db:delete-list list-id)
     (define lists-after-delete (get-all-lists))
     (check-equal? (length lists-after-delete) 4)
     
     ;; 测试删除不存在的列表
     (db:delete-list 9999)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试空列表情况
   (test-case "测试空列表情况" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 先删除所有列表（通过直接操作数据库）
     (define conn (db:current-db-connection))
     (query-exec conn "DELETE FROM task") ; 先删除所有任务
     (query-exec conn "DELETE FROM list") ; 再删除所有列表
     
     ;; 测试空列表情况
     (define empty-lists (get-all-lists))
     (check-pred list? empty-lists)
     (check-equal? (length empty-lists) 0)
     
     ;; 测试空列表时获取默认列表
     (define default-list-empty (get-default-list))
     (check-false default-list-empty)
     
     ;; 测试向空列表添加第一个列表
     (add-list "第一个列表")
     (define lists-after-add (get-all-lists))
     (check-equal? (length lists-after-add) 1)
     
     ;; 测试获取默认列表（应该返回第一个列表）
     (define default-list-after-add (get-default-list))
     (check-pred todo-list? default-list-after-add)
     (check-equal? (todo-list-name default-list-after-add) "第一个列表")
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   
   ;; 测试级联删除
   (test-case "测试级联删除" 
     ;; 创建唯一的临时数据库文件
     (define temp-db-path (format "./test/temp-test-~a.db" (current-inexact-milliseconds)))
     
     ;; 确保临时文件不存在
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path))
     
     ;; 连接数据库
     (db:connect-to-database temp-db-path)
     
     ;; 添加测试列表
     (add-list "级联测试列表")
     (define lists (get-all-lists))
     (define test-list (last lists))
     (define test-list-id (todo-list-id test-list))
     
     ;; 向测试列表添加任务
     (db:add-task test-list-id "测试任务1" "2023-01-01" (current-seconds))
     (db:add-task test-list-id "测试任务2" #f (current-seconds))
     (db:add-task test-list-id "测试任务3" "2023-01-02" (current-seconds))
     
     ;; 检查任务是否添加成功
     (define conn (db:current-db-connection))
     (define task-count-before (query-value conn "SELECT COUNT(*) FROM task WHERE list_id = ?" test-list-id))
     (check-equal? task-count-before 3)
     
     ;; 删除列表
     (delete-list test-list-id)
     
     ;; 检查列表是否删除成功
     (define lists-after-delete (get-all-lists))
     (define found-list-after-delete (findf (lambda (lst) (= (todo-list-id lst) test-list-id)) lists-after-delete))
     (check-false found-list-after-delete)
     
     ;; 检查相关任务是否级联删除
     (define task-count-after (query-value conn "SELECT COUNT(*) FROM task WHERE list_id = ?" test-list-id))
     (check-equal? task-count-after 0)
     
     ;; 关闭连接并清理
     (db:close-database)
     (when (file-exists? temp-db-path)
       (delete-file temp-db-path)))
   ))

;; 运行测试套件
(run-tests list-tests)